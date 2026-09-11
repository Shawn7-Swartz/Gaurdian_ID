from fastapi import APIRouter

router = APIRouter()


@router.post("/identify")
def identify():
    return {
        "user_id": "child001",
        "role": "minor"
    }