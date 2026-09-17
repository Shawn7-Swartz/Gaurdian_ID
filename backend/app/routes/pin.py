import os

import bcrypt
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


class SetPinRequest(BaseModel):
    token: str
    pin: str


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


@router.post("/set-upi-pin")
def set_upi_pin(data: SetPinRequest):

    user = verify_token(data.token)
    user_id = user["user_id"]

    # UPI PIN must be exactly 4 or 6 digits
    if not data.pin.isdigit() or len(data.pin) not in (4, 6):
        raise HTTPException(
            status_code=400,
            detail="UPI PIN must contain exactly 4 or 6 digits"
        )

    # Hash the PIN using bcrypt
    pin_hash = bcrypt.hashpw(
        data.pin.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    response = (
        supabase
        .table("users")
        .update({
            "upi_pin_hash": pin_hash
        })
        .eq("id", user_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "message": "UPI PIN set successfully"
    }