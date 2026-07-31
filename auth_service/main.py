from __future__ import annotations

from typing import Dict, List, Literal, Optional
from uuid import uuid4

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="Guardian ID Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

EXPECTED_SEQUENCE = ["left", "center", "right"]
session_steps: Dict[str, List[str]] = {}

MINOR_SPEND_LIMIT = 500.0


class TransactionStartRequest(BaseModel):
    child_id: str = Field(default="child-001")
    amount: float


TransactionStatus = Literal["approved", "denied", "pending"]


class TransactionRecord(BaseModel):
    transaction_id: str
    child_id: str
    amount: float
    limit: float
    status: TransactionStatus
    decided_by: Optional[str] = None
    reason: Optional[str] = None


transactions: Dict[str, TransactionRecord] = {}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/liveness")
async def liveness(
    session_id: str = Form(...),
    target_position: str = Form(...),
    frame: UploadFile = File(...),
) -> dict[str, object]:
    await frame.read()

    history = session_steps.setdefault(session_id, [])
    expected_position = EXPECTED_SEQUENCE[len(history)]

    if target_position != expected_position:
        session_steps[session_id] = []
        return {
            "passed": False,
            "message": f"Expected {expected_position.upper()} but received {target_position.upper()}. Restarting sequence.",
            "next_target": EXPECTED_SEQUENCE[0],
        }

    history.append(target_position)

    if len(history) == len(EXPECTED_SEQUENCE):
        session_steps.pop(session_id, None)
        return {
            "passed": True,
            "message": "PASS: Liveness sequence completed successfully.",
            "next_target": None,
        }

    next_target = EXPECTED_SEQUENCE[len(history)]
    return {
        "passed": False,
        "message": f"Captured {target_position.upper()} successfully. Move to {next_target.upper()}.",
        "next_target": next_target,
    }


@app.post("/transactions/start")
def start_transaction(payload: TransactionStartRequest) -> TransactionRecord:
    amount = float(payload.amount)
    transaction_id = uuid4().hex
    status: TransactionStatus = "approved" if amount <= MINOR_SPEND_LIMIT else "pending"
    record = TransactionRecord(
        transaction_id=transaction_id,
        child_id=payload.child_id,
        amount=amount,
        limit=MINOR_SPEND_LIMIT,
        status=status,
        reason=None if status == "approved" else "Waiting for parent approval",
    )
    transactions[transaction_id] = record
    return record


@app.get("/transactions/{transaction_id}")
def get_transaction(transaction_id: str) -> TransactionRecord:
    return transactions[transaction_id]


@app.get("/transactions/pending")
def list_pending() -> list[TransactionRecord]:
    return [t for t in transactions.values() if t.status == "pending"]


class DecisionRequest(BaseModel):
    decision: Literal["approve", "deny"]
    parent_id: str = Field(default="parent-001")
    reason: Optional[str] = None


@app.post("/transactions/{transaction_id}/decision")
def decide_transaction(transaction_id: str, payload: DecisionRequest) -> TransactionRecord:
    record = transactions[transaction_id]
    record.decided_by = payload.parent_id
    if payload.decision == "approve":
        record.status = "approved"
        record.reason = payload.reason or "Approved by parent"
    else:
        record.status = "denied"
        record.reason = payload.reason or "Denied by parent"
    transactions[transaction_id] = record
    return record
