# app/services/reminders.py
import uuid
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

from app.crypto import encrypt
from app.db import SessionLocal
from app.models import Medication, Reminder, User


def next_fire(at: time, tz: str, after: datetime) -> datetime:
    """Momenti UTC i radhës kur ora lokale `at` ndodh pas `after`."""
    zone = ZoneInfo(tz)
    local = after.astimezone(zone)
    candidate = datetime.combine(local.date(), at, tzinfo=zone)
    if candidate <= local:
        candidate = datetime.combine(local.date() + timedelta(days=1), at, tzinfo=zone)
    return candidate.astimezone(timezone.utc)


async def create_reminder(user_id: uuid.UUID, medication: str, times: list[str]) -> None:
    now = datetime.now(timezone.utc)
    async with SessionLocal() as db:
        user = await db.get(User, user_id)
        med = Medication(user_id=user_id, name_enc=encrypt(medication), active=True)
        db.add(med)
        await db.flush()
        for hhmm in times:
            hh, mm = (int(x) for x in hhmm.split(":"))
            at = time(hh, mm)
            db.add(Reminder(user_id=user_id, medication_id=med.id, at_time=at,
                            tz=user.tz, next_fire_at=next_fire(at, user.tz, now),
                            active=True))
        await db.commit()
