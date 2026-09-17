import os

import hashlib
import hmac
import time
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

HMAC_SECRET = os.getenv("HMAC_SECRET")

if not HMAC_SECRET:
    raise ValueError("HMAC_SECRET is missing from .env")

if not SECRET_KEY:
    raise ValueError("JWT_SECRET is missing from .env")


class TransactionRequest(BaseModel):
    amount: int
    token: str
    pin: str
    timestamp: int
    signature: str

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

def verify_hmac(user_id: str, amount: int, timestamp: int, signature: str):

    current_time = int(time.time())

    # Reject requests older/newer than 5 minutes
    if abs(current_time - timestamp) > 300:
        raise HTTPException(
            status_code=401,
            detail="Request timestamp expired"
        )

    message = f"{user_id}|{amount}|{timestamp}"

    expected_signature = hmac.new(
        HMAC_SECRET.encode("utf-8"),
        message.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(
        signature,
        expected_signature
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid HMAC signature"
        )

@router.post("/transaction")
def make_transaction(data: TransactionRequest):

    # 1. Verify JWT
    user = verify_token(data.token)
    user_id = user["user_id"]
    
    # 2. Verify HMAC signature
    verify_hmac(
        user_id,
        data.amount,
        data.timestamp,
        data.signature
    )

    # 3. Get user from database
    user_response = (
        supabase
        .table("users")
        .select("*")
        .eq("id", user_id)
        .execute()
    )

    if not user_response.data:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user_data = user_response.data[0]
    role = user_data["role"]

    # 3. Verify UPI PIN
    pin_hash = user_data.get("upi_pin_hash")

    if not pin_hash:
        raise HTTPException(
            status_code=400,
            detail="UPI PIN has not been set"
        )

    if not data.pin.isdigit() or len(data.pin) not in (4, 6):
        raise HTTPException(
            status_code=400,
            detail="UPI PIN must contain exactly 4 or 6 digits"
        )

    if not bcrypt.checkpw(
        data.pin.encode("utf-8"),
        pin_hash.encode("utf-8")
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid UPI PIN"
        )

    # 4. Get account spending rule
    rule_response = (
        supabase
        .table("account_rules")
        .select("spending_limit")
        .eq("user_id", user_id)
        .execute()
    )

    if role == "major":
        spending_limit = float("inf")
    else:
        if not rule_response.data:
            raise HTTPException(
                status_code=404,
                detail="Account rule not found"
            )

        spending_limit = float(
            rule_response.data[0]["spending_limit"]
        )

    # 5. Apply RBAC spending rule
    if role == "minor" and data.amount > spending_limit:
        status = "pending"
    else:
        status = "approved"

    # 6. Create transaction
    transaction_response = (
        supabase
        .table("transactions")
        .insert({
            "user_id": user_id,
            "amount": data.amount,
            "status": status
        })
        .execute()
    )

    if not transaction_response.data:
        raise HTTPException(
            status_code=500,
            detail="Transaction could not be created"
        )

    transaction = transaction_response.data[0]

    return {
        "transaction_id": transaction["id"],
        "user_id": user_id,
        "amount": data.amount,
        "status": status
    }


@router.get("/transaction/{txn_id}")
def get_transaction(txn_id: str):

    response = (
        supabase
        .table("transactions")
        .select("*")
        .eq("id", txn_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )

    return response.data[0]