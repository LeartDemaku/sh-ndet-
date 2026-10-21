"""Kodi i verifikimit të emailit: gjenerim, hash dhe përmbajtje emaili.

Kodi nuk ruhet kurrë në tekst të qartë. Në databazë ruhet vetëm HMAC-SHA256
me një "pepper" sekret nga .env, kështu që edhe një dump i databazës nuk
zbulon kodin që përdoruesi ka marrë me email.
"""

from __future__ import annotations

import hashlib
import hmac
import secrets
from html import escape

from app.config import get_settings

TEST_EMAIL_DOMAINS = {
    "example.com",
    "example.net",
    "example.org",
    "test",
    "invalid",
    "localhost",
}


def generate_code() -> str:
    """Kod numerik 6-shifror (100000–999999), kriptografikisht i sigurt."""
    return f"{secrets.randbelow(900_000) + 100_000:06d}"


def _pepper(pepper: str | None) -> str:
    return pepper if pepper is not None else (
        get_settings().email_code_pepper or get_settings().jwt_secret
    )


def hash_code(code: str, pepper: str | None = None) -> str:
    """HMAC-SHA256; i njëjti kod + pepper japin gjithmonë të njëjtin hash."""
    return hmac.new(
        _pepper(pepper).encode("utf-8"),
        code.strip().encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def codes_match(code: str, code_hash: str, pepper: str | None = None) -> bool:
    """Krahasim në kohë konstante për të shmangur timing attacks."""
    return hmac.compare_digest(hash_code(code, pepper), code_hash)


def is_test_email(email: str) -> bool:
    """Adresa të rezervuara për teste; nuk dërgohet email real për to."""
    domain = email.rsplit("@", 1)[-1].strip().lower()
    return domain in TEST_EMAIL_DOMAINS


def mask_email(email: str) -> str:
    """Për logje: le***@gmail.com — nuk ekspozohet adresa e plotë."""
    try:
        local, domain = email.split("@", 1)
    except ValueError:
        return "***"
    if len(local) <= 2:
        masked_local = local[:1] + "***"
    else:
        masked_local = local[:2] + "***"
    return f"{masked_local}@{domain}"


def render_verification_email(code: str, ttl_minutes: int) -> tuple[str, str]:
    """Kthen (tekst, html) për emailin e verifikimit."""
    safe_code = escape(code)
    text = (
        "Shëndet+\n"
        "Kodi i verifikimit të llogarisë\n\n"
        f"Kodi yt është: {code}\n\n"
        f"Ky kod vlen {ttl_minutes} minuta dhe mund të përdoret vetëm një herë.\n"
        "Nëse nuk e kërkove ti, injoro këtë email. Llogaria nuk aktivizohet pa këtë kod.\n\n"
        "Shëndet+ është asistent AI, jo mjek. Në rast emergjence, telefono 194.\n"
        "Shëndet+ nuk të kërkon kurrë kodin me telefon ose në chat.\n"
    )
    html = f"""\
<!doctype html>
<html lang="sq">
  <body style="margin:0;padding:0;background:#f4faf9;font-family:Arial,Helvetica,sans-serif;color:#0f172a;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4faf9;padding:28px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:24px;overflow:hidden;border:1px solid #e2e8f0;">
            <tr>
              <td style="background:#0f766e;background-image:linear-gradient(135deg,#0b3b36,#0f766e,#14b8a6);padding:30px 32px;">
                <div style="font-size:26px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">Shëndet+</div>
                <div style="font-size:14px;color:rgba(255,255,255,0.82);margin-top:6px;">Shëndeti yt, i qartë dhe i sigurt</div>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;">
                <h1 style="margin:0 0 10px;font-size:22px;line-height:1.3;color:#0f172a;">Verifiko llogarinë tënde</h1>
                <p style="margin:0 0 22px;font-size:15px;line-height:1.6;color:#475569;">
                  Për të aktivizuar llogarinë, shkruaj kodin 6-shifror më poshtë në aplikacionin Shëndet+.
                </p>
                <div style="background:#f0fdfa;border:1px solid #ccfbf1;border-radius:18px;padding:22px;text-align:center;">
                  <div style="font-size:12px;font-weight:700;letter-spacing:1.6px;color:#0f766e;text-transform:uppercase;">Kodi i verifikimit</div>
                  <div style="font-size:38px;font-weight:800;letter-spacing:8px;color:#115e59;margin-top:8px;">{safe_code}</div>
                  <div style="font-size:13px;color:#64748b;margin-top:8px;">Vlen {ttl_minutes} minuta · përdoret vetëm një herë</div>
                </div>
                <p style="margin:22px 0 0;font-size:13px;line-height:1.6;color:#64748b;">
                  Nëse nuk e kërkove ti, injoro këtë email. Llogaria nuk aktivizohet pa këtë kod.
                  Shëndet+ nuk të kërkon kurrë kodin me telefon ose në chat.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:18px 32px;background:#f8fafc;border-top:1px solid #e2e8f0;">
                <p style="margin:0;font-size:12px;line-height:1.6;color:#64748b;">
                  Shëndet+ është asistent AI, jo mjek. Në rast emergjence, telefono <strong>194</strong>.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
"""
    return text, html
