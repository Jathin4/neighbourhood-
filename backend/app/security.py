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


# ponytail: stdlib PBKDF2 instead of adding bcrypt/passlib as a dependency.
# 600k iterations matches OWASP's 2023 minimum for PBKDF2-SHA256.
_PBKDF2_ITERATIONS = 600_000


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, _PBKDF2_ITERATIONS)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt_hex, digest_hex = stored_hash.split("$", 1)
    except ValueError:
        return False
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt_hex), _PBKDF2_ITERATIONS)
    return hmac.compare_digest(digest.hex(), digest_hex)


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
