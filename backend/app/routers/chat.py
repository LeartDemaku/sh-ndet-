import json
import logging
import uuid
from collections.abc import AsyncIterator

from agents import Runner
from agents.exceptions import InputGuardrailTripwireTriggered
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from openai.types.responses import ResponseTextDeltaEvent
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.agents.context import AppContext
from app.agents.registry import orchestrator
from app.config import get_settings
from app.crypto import decrypt, encrypt
from app.db import SessionLocal
from app.deps import get_current_user
from app.models import Conversation, Message, User
from app.ratelimit import rate_limit
from app.redis_client import redis
from app.safety.emergency import (
    EmergencyResult, check_emergency, emergency_message, emergency_number,
)
from app.services.consents import is_revoked

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/chat", tags=["chat"])


class ChatIn(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    conversation_id: uuid.UUID | None = None


def sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


async def _ensure_conversation(user_id: uuid.UUID, conv_id: uuid.UUID | None) -> uuid.UUID:
    async with SessionLocal() as db:
        if conv_id is None:
            conv = Conversation(user_id=user_id)
            db.add(conv)
            await db.commit()
            return conv.id
        conv = await db.get(Conversation, conv_id)
        if conv is None or conv.user_id != user_id:
            raise HTTPException(404, "Biseda nuk u gjet.")
        return conv.id


async def _history(conv_id: uuid.UUID, limit: int = 12) -> list[dict]:
    stmt = (
        select(Message).where(Message.conversation_id == conv_id)
        .order_by(Message.created_at.desc()).limit(limit)
    )
    async with SessionLocal() as db:
        rows = (await db.scalars(stmt)).all()
    return [{"role": m.role, "content": decrypt(m.content_enc)} for m in reversed(rows)]


async def _save(conv_id, role: str, text: str, safety=None, triage=None) -> None:
    async with SessionLocal() as db:
        db.add(Message(conversation_id=conv_id, role=role, content_enc=encrypt(text),
                       safety_level=safety, triage_level=triage))
        await db.commit()


async def _events(user: User, conv_id: uuid.UUID, history: list[dict], text: str,
                  keep_history: bool = True) -> AsyncIterator[str]:
    yield sse("meta", {"conversation_id": str(conv_id)})

    # 1) Shtresa deterministike: emergjencat PARA çdo thirrjeje të modelit.
    hit = check_emergency(text)
    if hit:
        msg = emergency_message(hit, user.country)
        if keep_history:
            await _save(conv_id, "assistant", msg, safety=hit.level)
        yield sse("emergency", {"level": hit.level, "message": msg})
        yield sse("done", {})
        return

    # 1b) Kill switch: vetëm L0 + mesazh statik (Pjesa 8, plani i incidenteve).
    if get_settings().safe_mode:
        num = emergency_number(user.country)
        msg = ("Shërbimi i përgjigjeve është përkohësisht i kufizuar për shkak të "
               "një kontrolli sigurie. Nuk mund të jap përgjigje tani.\n"
               f"Nëse është urgjente, telefono {num} ose shko në urgjencën më të afërt.")
        if keep_history:
            await _save(conv_id, "assistant", msg, safety="safe_mode")
        yield sse("blocked", {"message": msg, "safe_mode": True})
        yield sse("done", {})
        return

    # 2) Agjenti (me guardrail bllokues te orchestrator-i).
    ctx = AppContext(user_id=user.id, country=user.country, locale=user.locale)
    parts: list[str] = []
    try:
        run = Runner.run_streamed(
            orchestrator,
            input=history + [{"role": "user", "content": text}],
            context=ctx,
            max_turns=8,
        )
        async for ev in run.stream_events():
            if ev.type == "raw_response_event" and isinstance(ev.data, ResponseTextDeltaEvent):
                parts.append(ev.data.delta)
                yield sse("token", {"t": ev.data.delta})
    except InputGuardrailTripwireTriggered:
        msg = ("Nuk mund të ndihmoj me këtë kërkesë. Mund të pyesësh për simptoma, "
               "ilaçe, termine ose zakone të shëndetshme.")
        if keep_history:
            await _save(conv_id, "assistant", msg, safety="blocked")
        yield sse("blocked", {"message": msg})
        yield sse("done", {})
        return
    except Exception:
        logger.exception("agent_failed")
        num = emergency_number(user.country)
        yield sse("error", {"message": f"Ndodhi një gabim. Provo përsëri pas pak. "
                                       f"Nëse është urgjente, telefono {num}."})
        yield sse("done", {})
        return

    # 3) Rezultatet e strukturuara dhe veprimet që kërkojnë konfirmim.
    triage = ctx.triage
    if triage:
        yield sse("triage", triage.model_dump())
        if triage.level == "emergency":
            res = EmergencyResult("emergency", "triage", "")
            yield sse("emergency", {"level": "emergency",
                                    "message": emergency_message(res, user.country)})
    for action in ctx.pending_actions:
        action_id = uuid.uuid4().hex
        await redis.set(f"act:{user.id}:{action_id}", json.dumps(action), ex=600)
        yield sse("confirm", {"action_id": action_id, **action})

    if keep_history:
        await _save(conv_id, "assistant", "".join(parts).strip(),
                    triage=triage.level if triage else None)
    yield sse("done", {})


@router.post("/stream")
async def chat_stream(body: ChatIn, user: User = Depends(get_current_user)):
    await rate_limit(user.id)
    # Privatësia: nëse përdoruesi e ka tërhequr pëlqimin për historik, asgjë nuk ruhet.
    keep_history = not await is_revoked(user.id, "history")
    if keep_history:
        conv_id = await _ensure_conversation(user.id, body.conversation_id)
        history = await _history(conv_id)
        await _save(conv_id, "user", body.message)
    else:
        conv_id = uuid.uuid4()          # id fiktive: asnjë rresht në databazë
        history = []
    return StreamingResponse(
        _events(user, conv_id, history, body.message, keep_history),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
