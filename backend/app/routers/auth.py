import logging
import math
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import SessionLocal
from app.models import Consent, EmailVerification, User
from app.security import create_access_token, hash_password, verify_password
from app.services.email import EmailDeliveryError, send_verification_email
from app.services.email_verification import (
    codes_match,
    generate_code,
    hash_code,
    mask_email,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/auth", tags=["auth"])
CONSENT_VERSION = "2026-10"


class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=10, max_length=128)
    country: str = Field(default="XK", min_length=2, max_length=2)
    accept_terms: bool
    accept_health_data: bool          # pëlqim i veçantë, jo i kombinuar me kushtet


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(max_length=128)


class VerifyEmailIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendVerificationIn(BaseModel):
    email: EmailStr


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _issue_code(db: AsyncSession, user: User) -> tuple[str, EmailVerification]:
    """Anulon kodet e mëparshme dhe krijon një kod të ri, vetëm si hash."""
    now = _now()
    await db.execute(
        update(EmailVerification)
        .where(
            EmailVerification.user_id == user.id,
            EmailVerification.consumed_at.is_(None),
        )
        .values(consumed_at=now)
    )
    code = generate_code()
    s = get_settings()
    record = EmailVerification(
        user_id=user.id,
        code_hash=hash_code(code),
        expires_at=now + timedelta(minutes=s.email_code_ttl_minutes),
        attempts=0,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    logger.info(
        "verification_code_issued user_id=%s recipient=%s",
        user.id,
        mask_email(user.email),
    )
    return code, record


async def _deliver(email: str, code: str) -> bool:
    s = get_settings()
    try:
        return await send_verification_email(email, code, s.email_code_ttl_minutes)
    except EmailDeliveryError as exc:
        # Nuk ndalojmë regjistrimin: përdoruesi mund ta dërgojë kodin përsëri më vonë.
        logger.warning(
            "verification_email_delivery_failed recipient=%s error=%s",
            mask_email(email),
            exc,
        )
        return False


async def _latest_code(db: AsyncSession, user_id) -> EmailVerification | None:
    return await db.scalar(
        select(EmailVerification)
        .where(
            EmailVerification.user_id == user_id,
            EmailVerification.consumed_at.is_(None),
        )
        .order_by(EmailVerification.created_at.desc())
        .limit(1)
    )


@router.post("/register", status_code=201)
async def register(body: RegisterIn) -> dict:
    if not (body.accept_terms and body.accept_health_data):
        raise HTTPException(422, "Pëlqimet janë të detyrueshme për të vazhduar.")

    email = str(body.email).strip().lower()
    async with SessionLocal() as db:
        existing = await db.scalar(select(User.id).where(User.email == email))
        if existing:
            raise HTTPException(
                409,
                "Ky email është i regjistruar. Nëse nuk e ke verifikuar, "
                "hyr dhe dërgo kodin përsëri.",
            )

        user = User(
            email=email,
            password_hash=hash_password(body.password),
            country=body.country.upper(),
        )
        db.add(user)
        await db.flush()
        for kind in ("terms", "health_data"):
            db.add(Consent(user_id=user.id, kind=kind, version=CONSENT_VERSION))
        await db.commit()

        code, _ = await _issue_code(db, user)
        sent = await _deliver(email, code)

    s = get_settings()
    return {
        "verification_required": True,
        "email": email,
        "email_sent": sent,
        "expires_in": s.email_code_ttl_minutes * 60,
        "resend_after": s.email_code_resend_seconds,
        "message": (
            "Llogaria u krijua. Kontrollo emailin për kodin 6-shifror."
            if sent
            else "Llogaria u krijua, por emaili nuk u dërgua. "
                 "Provo ta dërgosh kodin përsëri nga ekrani i verifikimit."
        ),
    }


@router.post("/verify-email")
async def verify_email(body: VerifyEmailIn) -> dict:
    email = str(body.email).strip().lower()
    now = _now()
    s = get_settings()

    async with SessionLocal() as db:
        user = await db.scalar(
            select(User).where(User.email == email, User.deleted_at.is_(None))
        )
        if user is None:
            raise HTTPException(400, "Kodi nuk është i saktë ose ka skaduar.")

        # Idempotent: nëse është verifikuar më parë, kthehet token i ri.
        if user.email_verified_at is not None:
            return {"access_token": create_access_token(user.id), "token_type": "bearer"}

        record = await _latest_code(db, user.id)
        if record is None:
            raise HTTPException(
                400, "Kodi nuk ekziston ose ka skaduar. Kërko një kod të ri."
            )

        if record.expires_at <= now:
            record.consumed_at = now
            await db.commit()
            raise HTTPException(
                400, "Kodi ka skaduar. Kërko një kod të ri."
            )

        if record.attempts >= s.email_code_max_attempts:
            record.consumed_at = now
            await db.commit()
            raise HTTPException(
                429, "Shumë tentativa të pasakta. Kërko një kod të ri."
            )

        if not codes_match(body.code, record.code_hash):
            record.attempts += 1
            if record.attempts >= s.email_code_max_attempts:
                record.consumed_at = now
                await db.commit()
                raise HTTPException(
                    429,
                    "Shumë tentativa të pasakta. Kërko një kod të ri.",
                )
            await db.commit()
            raise HTTPException(
                400, "Kodi nuk është i saktë. Kontrollo dhe provo përsëri."
            )

        # Sukses: konsumohen të gjitha kodet aktive dhe llogaria aktivizohet.
        user.email_verified_at = now
        await db.execute(
            update(EmailVerification)
            .where(
                EmailVerification.user_id == user.id,
                EmailVerification.consumed_at.is_(None),
            )
            .values(consumed_at=now)
        )
        await db.commit()
        logger.info("email_verified user_id=%s", user.id)
        return {"access_token": create_access_token(user.id), "token_type": "bearer"}


@router.post("/resend-verification", status_code=202)
async def resend_verification(body: ResendVerificationIn) -> dict:
    """Dërgon kodin përsëri. Përgjigjet janë të përgjithshme për të mos zbuluar llogari."""
    email = str(body.email).strip().lower()
    now = _now()
    s = get_settings()
    generic = {
        "message": "Nëse llogaria ekziston dhe është e paverifikuar, "
                   "kodi i ri u dërgua.",
        "email_sent": False,
        "expires_in": s.email_code_ttl_minutes * 60,
        "resend_after": s.email_code_resend_seconds,
    }

    async with SessionLocal() as db:
        user = await db.scalar(
            select(User).where(User.email == email, User.deleted_at.is_(None))
        )
        if user is None or user.email_verified_at is not None:
            return generic

        latest = await db.scalar(
            select(EmailVerification)
            .where(EmailVerification.user_id == user.id)
            .order_by(EmailVerification.created_at.desc())
            .limit(1)
        )
        if latest is not None:
            elapsed = (now - latest.created_at).total_seconds()
            if elapsed < s.email_code_resend_seconds:
                retry = max(1, math.ceil(s.email_code_resend_seconds - elapsed))
                unit = "sekondë" if retry == 1 else "sekonda"
                raise HTTPException(
                    429,
                    f"Kodi u dërgua së fundmi. Provo përsëri pas {retry} {unit}.",
                    headers={"Retry-After": str(retry)},
                )

        count = await db.scalar(
            select(func.count(EmailVerification.id)).where(
                EmailVerification.user_id == user.id,
                EmailVerification.created_at >= now - timedelta(hours=1),
            )
        )
        if (count or 0) >= s.email_code_max_per_hour:
            raise HTTPException(
                429,
                "Shumë kërkesa për kod. Provo përsëri pas një ore.",
                headers={"Retry-After": "3600"},
            )

        code, _ = await _issue_code(db, user)
        sent = await _deliver(email, code)

    return {
        **generic,
        "email_sent": sent,
        "message": (
            "Kodi i ri u dërgua. Kontrollo emailin."
            if sent
            else "Kodi u krijua, por emaili nuk u dërgua. Provo përsëri pas pak."
        ),
    }


@router.post("/login")
async def login(body: LoginIn) -> dict:
    async with SessionLocal() as db:
        user = await db.scalar(
            select(User).where(
                User.email == str(body.email).strip().lower(),
                User.deleted_at.is_(None),
            )
        )
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Email ose fjalëkalim i pasaktë.")
    if user.email_verified_at is None:
        raise HTTPException(
            403,
            "Email nuk është verifikuar. Kontrollo kodin ose kërko një kod të ri.",
        )
    return {"access_token": create_access_token(user.id), "token_type": "bearer"}
