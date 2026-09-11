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


class LoginRequest(BaseModel):
    user_id: str


@router.post("/login")
def login(data: LoginRequest):

    response = (
        supabase
        .table("users")
        .select("*")
        .eq("id", data.user_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    user = response.data[0]

    payload = {
        "user_id": user["id"],
        "role": user["role"]
    }

    token = jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return {
        "access_token": token,
        "user_id": user["id"],
        "role": user["role"]
    }