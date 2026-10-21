import uuid
from datetime import datetime, timezone
from functools import lru_cache

from openai import AsyncOpenAI
from sqlalchemy import select

from app.config import get_settings
from app.db import SessionLocal
from app.models import KnowledgeChunk


@lru_cache
def _client() -> AsyncOpenAI:
    return AsyncOpenAI(api_key=get_settings().openai_api_key)


async def embed(texts: list[str]) -> list[list[float]]:
    resp = await _client().embeddings.create(
        model=get_settings().embedding_model, input=texts
    )
    return [d.embedding for d in resp.data]


def chunk_text(text: str, size: int = 900, overlap: int = 120) -> list[str]:
    text = " ".join(text.split())
    chunks, start = [], 0
    while start < len(text):
        end = min(start + size, len(text))
        chunks.append(text[start:end])
        if end == len(text):
            break
        start = end - overlap
    return chunks


async def ingest(title: str, source: str, url: str, lang: str, text: str,
                 reviewed_by: str | None = None) -> int:
    """Ngarkon një dokument burimor. reviewed_by plotësohet vetëm pas rishikimit klinik."""
    pieces = chunk_text(text)
    vectors = await embed(pieces)
    reviewed_at = datetime.now(timezone.utc) if reviewed_by else None
    async with SessionLocal() as db:
        for piece, vec in zip(pieces, vectors):
            db.add(KnowledgeChunk(id=uuid.uuid4(), source=source, title=title, url=url,
                                  lang=lang, text=piece, embedding=vec,
                                  reviewed_by=reviewed_by, reviewed_at=reviewed_at))
        await db.commit()
    return len(pieces)


async def search_knowledge(query: str, lang: str = "sq", k: int = 4) -> list[dict]:
    qvec = (await embed([query]))[0]
    stmt = (
        select(KnowledgeChunk)
        .where(KnowledgeChunk.reviewed_at.is_not(None),
               KnowledgeChunk.lang.in_([lang, "en"]))
        .order_by(KnowledgeChunk.embedding.cosine_distance(qvec))
        .limit(k)
    )
    async with SessionLocal() as db:
        rows = (await db.scalars(stmt)).all()
    return [{"title": r.title, "source": r.source, "url": r.url, "excerpt": r.text[:700]}
            for r in rows]
