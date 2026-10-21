# app/ratelimit.py
import time
import uuid

from fastapi import HTTPException

from app.config import get_settings
from app.redis_client import redis


async def rate_limit(user_id: uuid.UUID) -> None:
    """Dritare fikse 60 sekondash për përdorues. Hedh 429 kur kalohet kufiri."""
    limit = get_settings().rate_limit_per_min
    key = f"rl:{user_id}:{int(time.time() // 60)}"
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, 70)
    if count > limit:
        raise HTTPException(
            status_code=429,
            detail="Shumë kërkesa. Provo përsëri pas një minute.",
            headers={"Retry-After": "30"},
        )
