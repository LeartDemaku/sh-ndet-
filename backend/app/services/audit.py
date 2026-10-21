# app/services/audit.py
import uuid

from app.db import SessionLocal
from app.models import AuditLog


async def audit(user_id: uuid.UUID | None, action: str, resource: str = "", **meta) -> None:
    async with SessionLocal() as db:
        db.add(AuditLog(user_id=user_id, action=action, resource=resource, meta=meta))
        await db.commit()
