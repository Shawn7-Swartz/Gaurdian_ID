import os
from datetime import datetime, timezone, timedelta
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from jose import jwt
from dotenv import load_dotenv

from app.db.supabase_client import supabase

load_dotenv()

router = APIRouter()

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

if not SECRET_KEY:
    raise ValueError("JWT_SECRET is missing from .env")


class LivenessRequest(BaseModel):
    token: str
    result: Literal["PASS", "FAIL"]


def verify_token(token: str):
    try:
        return jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )


@router.post("/liveness")
def check_liveness(data: LivenessRequest):

    # 1. Verify JWT
    user = verify_token(data.token)
    user_id = user["user_id"]

    # 2. Get user from database
    response = (
        supabase
        .table("users")
        .select("id, name, role, liveness_failures, blocked_until")
        .eq("id", user_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user_data = response.data[0]

    failures = user_data["liveness_failures"] or 0
    blocked_until = user_data["blocked_until"]

    now = datetime.now(timezone.utc)

    # 3. Check whether user is currently blocked
    if blocked_until:
        blocked_time = datetime.fromisoformat(
            blocked_until.replace("Z", "+00:00")
        )

        if now < blocked_time:
            remaining_seconds = int(
                (blocked_time - now).total_seconds()
            )

            raise HTTPException(
                status_code=403,
                detail={
                    "message": "User temporarily blocked",
                    "blocked_until": blocked_until,
                    "remaining_seconds": remaining_seconds
                }
            )

        # Block period expired → reset
        failures = 0

        supabase.table("users").update({
            "liveness_failures": 0,
            "blocked_until": None
        }).eq("id", user_id).execute()

    # 4. Successful liveness
    if data.result == "PASS":

        supabase.table("users").update({
            "liveness_failures": 0,
            "blocked_until": None
        }).eq("id", user_id).execute()

        return {
            "status": "PASS",
            "message": "Liveness verification successful",
            "liveness_failures": 0
        }

    # 5. Failed liveness
    failures += 1

    # 6. Three consecutive failures → block for 5 minutes
    if failures >= 3:

        blocked_until_time = now + timedelta(minutes=5)

        supabase.table("users").update({
            "liveness_failures": failures,
            "blocked_until": blocked_until_time.isoformat()
        }).eq("id", user_id).execute()

        raise HTTPException(
            status_code=403,
            detail={
                "message": "Too many failed liveness attempts. User blocked for 5 minutes.",
                "blocked_until": blocked_until_time.isoformat(),
                "liveness_failures": failures
            }
        )

    # 7. Store failed attempt
    supabase.table("users").update({
        "liveness_failures": failures
    }).eq("id", user_id).execute()

    raise HTTPException(
        status_code=401,
        detail={
            "message": "Liveness verification failed",
            "liveness_failures": failures,
            "attempts_remaining": 3 - failures
        }
    )