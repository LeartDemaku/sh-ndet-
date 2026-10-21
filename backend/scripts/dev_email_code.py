"""Vetëm për zhvillim/teste: krijon një kod verifikimi për një email test.

Përdorimi (nga dosja backend):
    .venv\\Scripts\\python.exe scripts\\dev_email_code.py test@example.com

Kodi shtypet vetëm në stdout, që smoke-test-i ta përdorë. Nuk ekzekutohet
kurrë në production dhe pranon vetëm adresa të rezervuara për teste.
"""

from __future__ import annotations

import asyncio
import os
import sys
from datetime import datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, update  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.db import SessionLocal, engine  # noqa: E402
from app.models import EmailVerification, User  # noqa: E402
from app.services.email_verification import (  # noqa: E402
    generate_code,
    hash_code,
    is_test_email,
)


async def main(email: str) -> int:
    email = email.strip().lower()
    settings = get_settings()
    if settings.app_env == "production":
        print("Nuk lejohet në production.", file=sys.stderr)
        return 2
    if not is_test_email(email):
        print("Vetëm adresa test (p.sh. @example.com) lejohen.", file=sys.stderr)
        return 2

    now = datetime.now(timezone.utc)
    async with SessionLocal() as db:
        user = await db.scalar(
            select(User).where(User.email == email, User.deleted_at.is_(None))
        )
        if user is None:
            print("Përdoruesi nuk u gjet.", file=sys.stderr)
            return 1
        if user.email_verified_at is not None:
            print("Përdoruesi është verifikuar më parë.", file=sys.stderr)
            return 1

        await db.execute(
            update(EmailVerification)
            .where(
                EmailVerification.user_id == user.id,
                EmailVerification.consumed_at.is_(None),
            )
            .values(consumed_at=now)
        )
        code = generate_code()
        db.add(EmailVerification(
            user_id=user.id,
            code_hash=hash_code(code),
            expires_at=now + timedelta(minutes=settings.email_code_ttl_minutes),
            attempts=0,
        ))
        await db.commit()

    print(code)
    await engine.dispose()
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Përdorimi: dev_email_code.py <email>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(asyncio.run(main(sys.argv[1])))
