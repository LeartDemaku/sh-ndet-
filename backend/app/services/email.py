"""Dërgimi i emailit të verifikimit përmes SMTP (Gmail).

Sekreti SMTP lexohet vetëm nga app.config (backend/.env). Nuk logohet dhe
nuk kthehet kurrë në API. Nëse mjedisi është test, emaili nuk dërgohet.
"""

from __future__ import annotations

import asyncio
import logging
import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr

from app.config import get_settings
from app.services.email_verification import (
    is_test_email,
    mask_email,
    render_verification_email,
)

logger = logging.getLogger(__name__)


class EmailDeliveryError(RuntimeError):
    """SMTP nuk arriti ta dorëzojë emailin (pa ekspozuar sekretin)."""


def _send_sync(to: str, code: str, ttl_minutes: int) -> None:
    s = get_settings()
    if not s.smtp_configured:
        raise EmailDeliveryError("SMTP nuk është konfiguruar në backend/.env")

    sender = s.smtp_from or s.smtp_user
    text, html = render_verification_email(code, ttl_minutes)

    msg = EmailMessage()
    msg["Subject"] = "Kodi i verifikimit – Shëndet+"
    msg["From"] = formataddr(("Shëndet+", sender))
    msg["To"] = to
    msg["X-Mailer"] = "Shëndet+"
    msg.set_content(text)
    msg.add_alternative(html, subtype="html")

    context = ssl.create_default_context()
    password = s.smtp_password.replace(" ", "")

    try:
        if s.smtp_use_ssl or s.smtp_port == 465:
            with smtplib.SMTP_SSL(
                s.smtp_host, s.smtp_port, timeout=20, context=context
            ) as server:
                server.login(s.smtp_user, password)
                server.send_message(msg)
        else:
            with smtplib.SMTP(s.smtp_host, s.smtp_port, timeout=20) as server:
                server.ehlo()
                if s.smtp_starttls:
                    server.starttls(context=context)
                    server.ehlo()
                server.login(s.smtp_user, password)
                server.send_message(msg)
    except (smtplib.SMTPException, OSError) as exc:
        # Nuk përfshihet kodi dhe as fjalëkalimi në log.
        raise EmailDeliveryError(
            f"SMTP dështoi për {mask_email(to)}: {type(exc).__name__}"
        ) from exc


async def send_verification_email(to: str, code: str, ttl_minutes: int) -> bool:
    """Kthen True kur emaili u pranua nga serveri SMTP.

    Adresat e rezervuara për teste (@example.com etj.) nuk marrin email real;
    kjo shmang dërgimin e emaileve të panevojshme gjatë smoke-test-eve.
    """
    if is_test_email(to):
        logger.info("verification_email_skipped_test_domain recipient=%s", mask_email(to))
        return False

    try:
        await asyncio.to_thread(_send_sync, to, code, ttl_minutes)
    except EmailDeliveryError:
        raise
    except Exception as exc:  # pragma: no cover - rrjet/konfigurim
        logger.exception("verification_email_failed recipient=%s", mask_email(to))
        raise EmailDeliveryError(
            f"Emaili nuk u dërgua për {mask_email(to)}: {type(exc).__name__}"
        ) from exc

    logger.info("verification_email_sent recipient=%s", mask_email(to))
    return True
