# app/redis_client.py
import redis.asyncio as aioredis

from app.config import get_settings

redis = aioredis.from_url(get_settings().redis_url, decode_responses=True)
