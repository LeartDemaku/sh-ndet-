# app/routers/actions.py
import json

from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_current_user
from app.models import User
from app.redis_client import redis
from app.services.audit import audit
from app.services.reminders import create_reminder

router = APIRouter(prefix="/v1/actions", tags=["actions"])


@router.post("/{action_id}/confirm")
async def confirm(action_id: str, user: User = Depends(get_current_user)) -> dict:
    """Ekzekuton vetëm veprimin e ruajtur nga serveri. Klienti nuk dërgon të dhëna."""
    raw = await redis.getdel(f"act:{user.id}:{action_id}")   # përdoret vetëm një herë
    if raw is None:
        raise HTTPException(404, "Veprimi ka skaduar ose nuk ekziston.")
    action = json.loads(raw)
    if action["type"] != "create_reminder":
        raise HTTPException(400, "Lloj veprimi i panjohur.")
    await create_reminder(user.id, action["medication"], action["times"])
    await audit(user.id, "action.confirm", action["type"])
    return {"status": "done"}
