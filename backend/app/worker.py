import asyncio
from datetime import datetime, timezone

import firebase_admin
from arq import cron
from arq.connections import RedisSettings
from firebase_admin import messaging
from sqlalchemy import delete, select

from app.config import get_settings
from app.db import SessionLocal
from app.models import Device, Reminder
from app.services.reminders import next_fire


async def startup(ctx: dict) -> None:
    firebase_admin.initialize_app()        # lexon GOOGLE_APPLICATION_CREDENTIALS


async def send_due_reminders(ctx: dict) -> None:
    now = datetime.now(timezone.utc)
    stmt = (
        select(Reminder)
        .where(Reminder.active.is_(True), Reminder.next_fire_at <= now)
        .order_by(Reminder.next_fire_at)
        .limit(500)
        .with_for_update(skip_locked=True)   # disa workers pa dyfishim
    )
    async with SessionLocal() as db:
        for r in (await db.scalars(stmt)).all():
            tokens = (await db.scalars(
                select(Device.fcm_token).where(Device.user_id == r.user_id))).all()
            for token in tokens:
                msg = messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title="Kujtesë",                       # pa emrin e ilaçit
                        body="Hape aplikacionin për detajet.",  # privatësi në ekran
                    ),
                    data={"reminder_id": str(r.id)},
                )
                try:
                    await asyncio.to_thread(messaging.send, msg)
                except messaging.UnregisteredError:
                    await db.execute(delete(Device).where(Device.fcm_token == token))
            r.next_fire_at = next_fire(r.at_time, r.tz, now)
        await db.commit()


class WorkerSettings:
    on_startup = startup
    cron_jobs = [cron(send_due_reminders)]          # çdo minutë (second=0)
    redis_settings = RedisSettings.from_dsn(get_settings().redis_url)
