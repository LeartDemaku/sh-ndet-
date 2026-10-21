from functools import lru_cache

from cryptography.fernet import Fernet, MultiFernet

from app.config import get_settings


@lru_cache
def _fernet() -> MultiFernet:
    keys = get_settings().encryption_keys
    if not keys:
        raise RuntimeError("FIELD_ENCRYPTION_KEYS mungon në .env")
    # Çelësi i parë enkripton; të gjithë mund të dekriptojnë (rotacion pa ndërprerje).
    return MultiFernet([Fernet(k.encode("ascii")) for k in keys])


def encrypt(text: str) -> str:
    return _fernet().encrypt(text.encode("utf-8")).decode("ascii")


def decrypt(token: str) -> str:
    return _fernet().decrypt(token.encode("ascii")).decode("utf-8")
