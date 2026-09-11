import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from jose import jwt
from dotenv import load_dotenv
from typing import Literal

from app.db.supabase_client import supabase

load_dotenv()

router = APIRouter()

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

if not SECRET_KEY:
    raise ValueError("JWT_SECRET is missing from .env")


class ApprovalRequest(BaseModel):
    transaction_id: str
    action: Literal["approve", "reject"]
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


@router.post("/approve")
def approve_transaction(data: ApprovalRequest):

    # 1. Verify JWT
    parent = verify_token(data.token)

    parent_id = parent["user_id"]

    # 2. Get parent from Supabase
    parent_response = (
        supabase
        .table("users")
        .select("*")
        .eq("id", parent_id)
        .execute()
    )

    if not parent_response.data:
        raise HTTPException(
            status_code=404,
            detail="Parent user not found"
        )

    parent_data = parent_response.data[0]

    # 3. Verify parent role
    if parent_data["role"] != "major":
        raise HTTPException(
            status_code=403,
            detail="Only a parent can approve transactions"
        )

    # 4. Find transaction
    transaction_response = (
        supabase
        .table("transactions")
        .select("*")
        .eq("id", data.transaction_id)
        .execute()
    )

    if not transaction_response.data:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )

    transaction = transaction_response.data[0]

    # 5. Transaction must be pending
    if transaction["status"] != "pending":
        raise HTTPException(
            status_code=400,
            detail="Transaction is not pending"
        )

    child_id = transaction["user_id"]

    # 6. Find child
    child_response = (
        supabase
        .table("users")
        .select("*")
        .eq("id", child_id)
        .execute()
    )

    if not child_response.data:
        raise HTTPException(
            status_code=404,
            detail="Child user not found"
        )

    child = child_response.data[0]

    # 7. Verify parent-child relationship
    if child["parent_id"] != parent_id:
        raise HTTPException(
            status_code=403,
            detail="You are not authorized to approve this transaction"
        )

    # 8. Determine new status
    if data.action == "approve":
        new_status = "approved"
    else:
        new_status = "rejected"

    # 9. Update transaction
    update_response = (
        supabase
        .table("transactions")
        .update({
            "status": new_status
        })
        .eq("id", data.transaction_id)
        .execute()
    )

    if not update_response.data:
        raise HTTPException(
            status_code=500,
            detail="Transaction could not be updated"
        )

    return {
        "transaction_id": data.transaction_id,
        "status": new_status,
        "approved_by": parent_id
    }