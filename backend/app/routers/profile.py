# app/routers/profile.py
# E drejta e përdoruesit: informim, qasje/portabilitet, korrigjim, fshirje,
# kufizim dhe tërheqje pëlqimi (GDPR neni 15-22 / Ligji nr. 06/L-082).
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import delete, select, update

from app.crypto import decrypt
from app.db import SessionLocal
from app.deps import get_current_user
from app.models import (
    AuditLog,
    Consent,
    Conversation,
    Device,
    Medication,
    Message,
    Reminder,
    User,
)
from app.services.audit import audit
from app.services.consents import KNOWN_KINDS, get_consent, set_consent

router = APIRouter(prefix="/v1", tags=["profile"])

# Afati brenda të cilit job-i i periodikëm kryer fshirjen fizike të rreshtit të
# anonymizuar (udhëzimi: "fshirje e plotë nga një job brenda afatit të caktuar").
PURGE_AFTER_DAYS = 30


class ProfileIn(BaseModel):
    first_name: str | None = Field(default=None, min_length=1, max_length=80)
    last_name: str | None = Field(default=None, min_length=1, max_length=80)
    country: str | None = Field(default=None, min_length=2, max_length=2)
    locale: str | None = Field(default=None, min_length=2, max_length=5)
    tz: str | None = Field(default=None, min_length=1, max_length=40)

    @field_validator("first_name", "last_name")
    @classmethod
    def _clean_optional_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Emri nuk mund të jetë bosh.")
        return cleaned


class ConsentBody(BaseModel):
    granted: bool


class DeleteBody(BaseModel):
    confirm: bool


@router.get("/me")
async def read_me(user: User = Depends(get_current_user)) -> dict:
    async with SessionLocal() as db:
        consents = (await db.scalars(
            select(Consent).where(Consent.user_id == user.id)
            .order_by(Consent.granted_at.desc()))).all()
    return {
        "profile": {
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "country": user.country,
            "locale": user.locale,
            "tz": user.tz,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        },
        "consents": [
            {"kind": c.kind, "version": c.version,
             "granted_at": c.granted_at.isoformat() if c.granted_at else None,
             "revoked_at": c.revoked_at.isoformat() if c.revoked_at else None,
             "granted": c.revoked_at is None}
            for c in consents
        ],
        "consent_version": consents[0].version if consents else None,
    }


@router.patch("/me")
async def correct_me(body: ProfileIn, user: User = Depends(get_current_user)) -> dict:
    """Korrigjim i të dhënave (tabela GDPR: 'Korrigjim -> Ndryshim te Profili')."""
    values = {k: v for k, v in body.model_dump().items() if v is not None}
    if not values:
        raise HTTPException(422, "Asnjë fushë për t'u ndryshuar.")
    if "country" in values:
        values["country"] = values["country"].upper()
    async with SessionLocal() as db:
        await db.execute(update(User).where(User.id == user.id).values(**values))
        await db.commit()
    await audit(user.id, "profile.update", "user", fields=sorted(values))
    return {"status": "updated", "fields": sorted(values)}


@router.get("/me/medications")
async def list_medications(user: User = Depends(get_current_user)) -> dict:
    """Lista e ilaçeve aktive me oraret e kujtesave (Ekrani 5 · Ilaçet)."""
    async with SessionLocal() as db:
        meds = (await db.scalars(
            select(Medication)
            .where(Medication.user_id == user.id, Medication.active.is_(True))
            .order_by(Medication.created_at))).all()
        med_ids = [m.id for m in meds]
        times: dict[uuid.UUID, list[str]] = {}
        if med_ids:
            rows = (await db.execute(
                select(Reminder.medication_id, Reminder.at_time)
                .where(Reminder.medication_id.in_(med_ids)))).all()
            for mid, at in rows:
                times.setdefault(mid, []).append(at.strftime("%H:%M"))

    return {
        "medications": [
            {"id": str(m.id), "name": decrypt(m.name_enc),
             "times": sorted(times.get(m.id, []))}
            for m in meds
        ],
    }


@router.delete("/me/medications")
async def delete_all_medications(user: User = Depends(get_current_user)) -> dict:
    """Fshin të gjitha ilaçet e përdoruesit dhe kujtesat e tyre."""
    async with SessionLocal() as db:
        med_ids = (await db.scalars(
            select(Medication.id).where(Medication.user_id == user.id)
        )).all()
        if med_ids:
            await db.execute(
                delete(Reminder).where(
                    Reminder.user_id == user.id,
                    Reminder.medication_id.in_(med_ids),
                )
            )
            await db.execute(
                delete(Medication).where(Medication.user_id == user.id)
            )
            await db.commit()

    if med_ids:
        await audit(user.id, "medication.delete_all", "medication", count=len(med_ids))
    return {"status": "deleted", "count": len(med_ids)}


@router.delete("/me/medications/{medication_id}")
async def delete_medication(
    medication_id: uuid.UUID,
    user: User = Depends(get_current_user),
) -> dict:
    """Fshin një ilaç të përdoruesit dhe kujtesat e tij.

    Fshirja është e menjëhershme dhe e pakthyeshme; ilaçi duhet t'i përkasë
    përdoruesit që e kërkon. Kujtesat fshihen para ilaçit, edhe pse FK-ja ka
    ON DELETE CASCADE, që sjellja të mos varet nga konfigurimi i bazës.
    """
    async with SessionLocal() as db:
        medication = await db.scalar(
            select(Medication).where(
                Medication.id == medication_id,
                Medication.user_id == user.id,
            )
        )
        if medication is None:
            raise HTTPException(404, "Ilaçi nuk u gjet.")
        await db.execute(
            delete(Reminder).where(
                Reminder.medication_id == medication.id,
                Reminder.user_id == user.id,
            )
        )
        await db.delete(medication)
        await db.commit()

    await audit(
        user.id,
        "medication.delete",
        "medication",
        medication_id=str(medication_id),
    )
    return {"status": "deleted", "id": str(medication_id)}


@router.delete("/me/conversations")
async def delete_all_conversations(user: User = Depends(get_current_user)) -> dict:
    """Fshin të gjitha bisedat e përdoruesit (mesazhet shkojnë me to)."""
    async with SessionLocal() as db:
        conv_ids = (await db.scalars(
            select(Conversation.id).where(Conversation.user_id == user.id)
        )).all()
        if conv_ids:
            await db.execute(
                delete(Message).where(Message.conversation_id.in_(conv_ids))
            )
            await db.execute(
                delete(Conversation).where(Conversation.user_id == user.id)
            )
            await db.commit()

    if conv_ids:
        await audit(
            user.id,
            "conversation.delete_all",
            "conversation",
            count=len(conv_ids),
        )
    return {"status": "deleted", "count": len(conv_ids)}


@router.delete("/me/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: uuid.UUID,
    user: User = Depends(get_current_user),
) -> dict:
    """Fshin një bisedë vetëm nëse i përket përdoruesit aktual."""
    async with SessionLocal() as db:
        conversation = await db.scalar(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user.id,
            )
        )
        if conversation is None:
            raise HTTPException(404, "Biseda nuk u gjet.")
        await db.execute(
            delete(Message).where(Message.conversation_id == conversation.id)
        )
        await db.delete(conversation)
        await db.commit()

    await audit(
        user.id,
        "conversation.delete",
        "conversation",
        conversation_id=str(conversation_id),
    )
    return {"status": "deleted", "id": str(conversation_id)}


@router.get("/me/export")
async def export_me(user: User = Depends(get_current_user)) -> dict:
    """E drejta e qasjes dhe portabilitetit: JSON me profilin, pëlqimet, ilaçet, bisedat."""
    async with SessionLocal() as db:
        consents = (await db.scalars(
            select(Consent).where(Consent.user_id == user.id))).all()

        meds = (await db.scalars(
            select(Medication).where(Medication.user_id == user.id)
            .order_by(Medication.created_at))).all()
        med_ids = [m.id for m in meds]
        times: dict[uuid.UUID, list[str]] = {}
        if med_ids:
            rows = (await db.execute(
                select(Reminder.medication_id, Reminder.at_time)
                .where(Reminder.medication_id.in_(med_ids)))).all()
            for mid, at in rows:
                times.setdefault(mid, []).append(at.strftime("%H:%M"))

        convs = (await db.scalars(
            select(Conversation).where(Conversation.user_id == user.id)
            .order_by(Conversation.created_at))).all()
        conversations = []
        for c in convs:
            msgs = (await db.scalars(
                select(Message).where(Message.conversation_id == c.id)
                .order_by(Message.created_at))).all()
            conversations.append({
                "id": str(c.id),
                "created_at": c.created_at.isoformat() if c.created_at else None,
                "messages": [{
                    "role": m.role,
                    "content": decrypt(m.content_enc),
                    "safety_level": m.safety_level,
                    "triage_level": m.triage_level,
                    "created_at": m.created_at.isoformat() if m.created_at else None,
                } for m in msgs],
            })

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "profile": {
            "id": str(user.id),
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "country": user.country,
            "locale": user.locale,
            "tz": user.tz,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        },
        "consents": [
            {"kind": c.kind, "version": c.version,
             "granted_at": c.granted_at.isoformat() if c.granted_at else None,
             "revoked_at": c.revoked_at.isoformat() if c.revoked_at else None}
            for c in consents
        ],
        "medications": [
            {"id": str(m.id), "name": decrypt(m.name_enc), "active": m.active,
             "created_at": m.created_at.isoformat() if m.created_at else None,
             "times": times.get(m.id, [])}
            for m in meds
        ],
        "conversations": conversations,
    }


@router.get("/me/consents/{kind}")
async def read_consent(kind: str, user: User = Depends(get_current_user)) -> dict:
    if kind not in KNOWN_KINDS:
        raise HTTPException(404, "Lloj pëlqimi i panjohur.")
    row = await get_consent(user.id, kind)
    return {"kind": kind, "granted": row is None or row.revoked_at is None,
            "version": row.version if row else None}


@router.put("/me/consents/{kind}")
async def write_consent(kind: str, body: ConsentBody,
                        user: User = Depends(get_current_user)) -> dict:
    """Dhënia ose tërheqja e pëlqimit (revoked_at te tabela consents)."""
    if kind not in KNOWN_KINDS:
        raise HTTPException(404, "Lloj pëlqimi i panjohur.")
    result = await set_consent(user.id, kind, body.granted)
    await audit(user.id, "consent.update", kind, granted=body.granted)
    return result


@router.delete("/me")
async def delete_me(body: DeleteBody, user: User = Depends(get_current_user)) -> dict:
    """Çaktivizim i menjëhershëm + fshirje e të dhënave personale.

    - tokenët ekzistues ndalojnë së punuari (deleted_at kontrollohet në deps)
    - email dhe fjalëkalim anonymizohen (pa identifikues)
    - bisedat, ilaçet, kujtesat, pajisjet dhe pëlqimet fshihen menjëherë
    - audit_logs mbeten, por pa identifikues
    - rreshti i anonymizuar fshihet fizikisht nga job-i pas afatit të caktuar
    """
    if not body.confirm:
        raise HTTPException(422, "Konfirmo fshirjen (confirm: true).")

    now = datetime.now(timezone.utc)
    purge_by = now + timedelta(days=PURGE_AFTER_DAYS)

    async with SessionLocal() as db:
        target = await db.get(User, user.id)
        if target is None:
            raise HTTPException(401, "Përdoruesi nuk ekziston.")

        # 1) Çaktivizim i menjëhershëm
        target.deleted_at = now
        # 2) Pa identifikues: email dhe fjalëkalim anonymizohen
        target.email = f"erased-{uuid.uuid4().hex[:16]}@erased.invalid"
        target.password_hash = secrets.token_urlsafe(48)
        target.first_name = None
        target.last_name = None

        # 3) Përmbajtja personale fshihet menjëherë (tabelat fqinje me CASCADE)
        await db.execute(delete(Conversation).where(Conversation.user_id == user.id))
        await db.execute(delete(Medication).where(Medication.user_id == user.id))
        await db.execute(delete(Device).where(Device.user_id == user.id))
        await db.execute(delete(Consent).where(Consent.user_id == user.id))

        # 4) audit_logs mbeten, por pa identifikues
        await db.execute(
            update(AuditLog).where(AuditLog.user_id == user.id).values(user_id=None)
        )
        await db.commit()

    # Log pa PII (user_id = None): log-u i fshirjes mbetet pa identifikues
    await audit(None, "user.delete", "user", purge_by=purge_by.isoformat())
    return {"status": "deleted", "deleted_at": now.isoformat(),
            "purge_by": purge_by.isoformat()}
