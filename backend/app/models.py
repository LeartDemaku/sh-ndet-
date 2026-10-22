import uuid
from datetime import datetime, time

from pgvector.sqlalchemy import Vector
from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, Time, Uuid, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base

EMBED_DIM = 1536  # duhet të përputhet me EMBEDDING_DIM te .env
TS = DateTime(timezone=True)


def pk() -> Mapped[uuid.UUID]:
    return mapped_column(Uuid, primary_key=True, default=uuid.uuid4)


def fk_user() -> Mapped[uuid.UUID]:
    return mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)


class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = pk()
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    first_name: Mapped[str | None] = mapped_column(String(80))
    last_name: Mapped[str | None] = mapped_column(String(80))
    country: Mapped[str] = mapped_column(String(2), default="XK")
    locale: Mapped[str] = mapped_column(String(5), default="sq")
    tz: Mapped[str] = mapped_column(String(40), default="Europe/Belgrade")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    email_verified_at: Mapped[datetime | None] = mapped_column(TS)
    deleted_at: Mapped[datetime | None] = mapped_column(TS)


class EmailVerification(Base):
    """Kodi i verifikimit të emailit; ruhet vetëm hash-i HMAC."""
    __tablename__ = "email_verifications"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    code_hash: Mapped[str] = mapped_column(String(64))
    attempts: Mapped[int] = mapped_column(default=0, server_default="0")
    expires_at: Mapped[datetime] = mapped_column(TS, index=True)
    consumed_at: Mapped[datetime | None] = mapped_column(TS)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)


class Consent(Base):
    __tablename__ = "consents"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    kind: Mapped[str] = mapped_column(String(32))      # terms | health_data | analytics
    version: Mapped[str] = mapped_column(String(16))
    granted_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    revoked_at: Mapped[datetime | None] = mapped_column(TS)


class Conversation(Base):
    __tablename__ = "conversations"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class Message(Base):
    __tablename__ = "messages"
    id: Mapped[uuid.UUID] = pk()
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(12))            # user | assistant
    content_enc: Mapped[str] = mapped_column(Text)           # tekst i enkriptuar
    safety_level: Mapped[str | None] = mapped_column(String(16))
    triage_level: Mapped[str | None] = mapped_column(String(24))
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)


class Medication(Base):
    __tablename__ = "medications"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    name_enc: Mapped[str] = mapped_column(Text)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class Reminder(Base):
    __tablename__ = "reminders"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    medication_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("medications.id", ondelete="CASCADE"), index=True
    )
    at_time: Mapped[time] = mapped_column(Time)
    tz: Mapped[str] = mapped_column(String(40))
    next_fire_at: Mapped[datetime] = mapped_column(TS, index=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Device(Base):
    __tablename__ = "devices"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk_user()
    fcm_token: Mapped[str] = mapped_column(String(255), unique=True)
    platform: Mapped[str] = mapped_column(String(10))        # android | ios


class KnowledgeChunk(Base):
    __tablename__ = "knowledge_chunks"
    id: Mapped[uuid.UUID] = pk()
    source: Mapped[str] = mapped_column(String(120))
    title: Mapped[str] = mapped_column(String(200))
    url: Mapped[str] = mapped_column(String(500))
    lang: Mapped[str] = mapped_column(String(5), index=True)
    text: Mapped[str] = mapped_column(Text)
    embedding: Mapped[list[float]] = mapped_column(Vector(EMBED_DIM))
    reviewed_by: Mapped[str | None] = mapped_column(String(80))
    reviewed_at: Mapped[datetime | None] = mapped_column(TS)


class AuditLog(Base):
    __tablename__ = "audit_logs"
    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, index=True)  # pa FK me qëllim
    action: Mapped[str] = mapped_column(String(48))
    resource: Mapped[str] = mapped_column(String(80), default="")
    meta: Mapped[dict] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)
