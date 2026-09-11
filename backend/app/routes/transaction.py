import os

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


class TransactionRequest(BaseModel):
    amount: int
    token: str


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


@router.post("/transaction")
def make_transaction(data: TransactionRequest):

    # 1. Verify JWT
    user = verify_token(data.token)

    user_id = user["user_id"]

    # 2. Get user from Supabase
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

    # 3. Get spending limit
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

    # 4. Apply RBAC transaction rule
    if role == "minor" and data.amount > spending_limit:
        status = "pending"
    else:
        status = "approved"

    # 5. Store transaction in Supabase
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