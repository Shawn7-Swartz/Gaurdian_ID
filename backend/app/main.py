from fastapi import FastAPI

from app.routes import auth, identify, transaction, approval, liveness, pin
from app.db.supabase_client import supabase

app = FastAPI(title="Guardian-ID Backend")


app.include_router(auth.router)
app.include_router(identify.router)
app.include_router(transaction.router)
app.include_router(approval.router)
app.include_router(liveness.router)
app.include_router(pin.router)


@app.get("/")
def root():
    return {"message": "Guardian-ID Backend Running"}


