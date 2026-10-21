# scripts/ingest_example.py   ->   python -m scripts.ingest_example   (nga dosja backend/)
import asyncio
from pathlib import Path

from app.services.rag import ingest


async def main() -> None:
    text = Path("burime/ftohja.txt").read_text(encoding="utf-8")
    n = await ingest(
        title="Ftohja e zakonshme: kujdesi në shtëpi",
        source="Emri i institucionit burimor",
        url="https://adresa-e-burimit.example/ftohja",
        lang="sq",
        text=text,
        reviewed_by="Emri i klinicistit",     # pa këtë, copëzat NUK kthehen te agjenti
    )
    print(f"U ngarkuan {n} copëza")


if __name__ == "__main__":
    asyncio.run(main())
