import hashlib
import hmac
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import jwt

from app.config import get_settings

settings = get_settings()


def sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def new_code(length: int | None = None) -> str:
    n = length or settings.otp_length
    return "".join(secrets.choice("0123456789") for _ in range(n))


def code_matches(code: str, code_hash: str) -> bool:
    return hmac.compare_digest(sha256(code), code_hash)


def opaque_token() -> str:
    return secrets.token_urlsafe(32)


def create_access_token(user_id: uuid.UUID) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_ttl_minutes),
        "typ": "access",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> uuid.UUID:
    data = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    if data.get("typ") != "access":
        raise jwt.InvalidTokenError("wrong token type")
    return uuid.UUID(data["sub"])


def refresh_expiry() -> datetime:
    return datetime.now(UTC) + timedelta(days=settings.refresh_token_ttl_days)
