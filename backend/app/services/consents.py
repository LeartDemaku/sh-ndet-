# app/services/consents.py
"""Pëlqimet e përdoruesit: lexim, dhënie dhe tërheqje (GDPR / Ligji 06/L-082).

Rregulli: një pëlqim konsiderohet i dhënë derisa të tërhiqet qartë (revoked_at).
Ekranet e Profilit përdorin këto funksione për çelësat "pa ruajtje historiku,
pa analitikë".
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import select

from app.db import SessionLocal
from app.models import Consent

CONSENT_VERSION = "2026-10"
KNOWN_KINDS = {"terms", "health_data", "analytics", "history", "notifications"}

# Pasojat që shfaqen te Profili kur përdoruesi tërheq një pëlqim
CONSEQUENCES = {
    "terms": "Pa kushtet e pranuara, llogaria nuk mund të përdoret më.",
    "health_data": "Të dhënat shëndetësore nuk përpunohen më: bisedat, ilaçet dhe kujtesat hiqen.",
    "history": "Historiku i bisedave nuk ruhet më. Bisedat e kaluara fshihen.",
    "analytics": "Analitikë anonime nuk mblidhet më.",
    "notifications": "Njoftimet e kujtesave ndalen.",
}


async def get_consent(user_id: uuid.UUID, kind: str) -> Consent | None:
    stmt = (
        select(Consent)
        .where(Consent.user_id == user_id, Consent.kind == kind)
        .order_by(Consent.granted_at.desc())
        .limit(1)
    )
    async with SessionLocal() as db:
        return await db.scalar(stmt)


async def is_revoked(user_id: uuid.UUID, kind: str) -> bool:
    """E vërtetë vetëm nëse përdoruesi e ka tërhequr qartë pëlqimin."""
    row = await get_consent(user_id, kind)
    return row is not None and row.revoked_at is not None


async def set_consent(user_id: uuid.UUID, kind: str, granted: bool) -> dict:
    now = datetime.now(timezone.utc)
    async with SessionLocal() as db:
        row = await db.scalar(
            select(Consent)
            .where(Consent.user_id == user_id, Consent.kind == kind)
            .order_by(Consent.granted_at.desc())
            .limit(1)
        )
        if granted:
            if row is None:
                db.add(Consent(user_id=user_id, kind=kind, version=CONSENT_VERSION))
            else:
                row.revoked_at = None
                row.version = CONSENT_VERSION
        else:
            if row is None:
                db.add(Consent(user_id=user_id, kind=kind, version=CONSENT_VERSION,
                               revoked_at=now))
            else:
                row.revoked_at = now
        await db.commit()
    return {"kind": kind, "granted": granted,
            "consequence": "" if granted else CONSEQUENCES.get(kind, "")}
