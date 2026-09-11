from fastapi import APIRouter

router = APIRouter()


@router.post("/liveness")
def liveness():
    return {
        "status": "PASS"
    }