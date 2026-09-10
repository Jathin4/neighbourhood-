import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.errors import AppError
from app.models.user import OtpChallenge, RefreshToken, User
from app.modules.identity.otp_adapter import get_sms_sender
from app.security import (
    code_matches,
    create_access_token,
    new_code,
    opaque_token,
    refresh_expiry,
    sha256,
)

settings = get_settings()


def _now() -> datetime:
    return datetime.now(UTC)


def _aware(dt: datetime) -> datetime:
    # SQLite round-trips naive datetimes; treat stored values as UTC.
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)


async def request_otp(db: AsyncSession, mobile: str) -> tuple[int, str | None]:
    hour_ago = _now() - timedelta(hours=1)
    recent = await db.scalar(
        select(func.count())
        .select_from(OtpChallenge)
        .where(OtpChallenge.mobile == mobile, OtpChallenge.created_at >= hour_ago)
    )
    if recent and recent >= settings.otp_max_requests_per_hour:
        raise AppError("otp_rate_limited", "Too many OTP requests, try later", 429)

    code = new_code()
    db.add(
        OtpChallenge(
            mobile=mobile,
            code_hash=sha256(code),
            expires_at=_now() + timedelta(seconds=settings.otp_ttl_seconds),
        )
    )
    await db.flush()
    await get_sms_sender().send_otp(mobile, code)
    return settings.otp_ttl_seconds, (code if settings.otp_debug else None)


async def verify_otp(db: AsyncSession, mobile: str, code: str) -> tuple[User, str, str]:
    challenge = await db.scalar(
        select(OtpChallenge)
        .where(OtpChallenge.mobile == mobile, OtpChallenge.consumed_at.is_(None))
        .order_by(OtpChallenge.created_at.desc())
    )
    if challenge is None:
        raise AppError("otp_not_found", "Request an OTP first", 400)
    if _aware(challenge.expires_at) < _now():
        raise AppError("otp_expired", "OTP expired", 400)
    if challenge.attempts >= settings.otp_max_attempts:
        raise AppError("otp_locked", "Too many attempts, request a new OTP", 429)

    challenge.attempts += 1
    if not code_matches(code, challenge.code_hash):
        await db.flush()
        raise AppError("otp_invalid", "Incorrect OTP", 400)

    challenge.consumed_at = _now()

    user = await db.scalar(select(User).where(User.mobile == mobile))
    if user is None:
        user = User(mobile=mobile)  # status defaults to 'pending'
        db.add(user)
        await db.flush()

    access, refresh = await _issue_pair(db, user.id)
    return user, access, refresh


async def dev_login(db: AsyncSession, mobile: str) -> tuple[User, str, str]:
    """Dev-only: skip OTP entirely and hand back tokens for ``mobile``."""
    if settings.env != "dev":
        raise AppError("not_available", "Dev login is disabled", 404)
    user = await db.scalar(select(User).where(User.mobile == mobile))
    if user is None:
        user = User(mobile=mobile)
        db.add(user)
        await db.flush()
    access, refresh = await _issue_pair(db, user.id)
    return user, access, refresh


async def _issue_pair(db: AsyncSession, user_id: uuid.UUID) -> tuple[str, str]:
    raw = opaque_token()
    db.add(RefreshToken(user_id=user_id, token_hash=sha256(raw), expires_at=refresh_expiry()))
    await db.flush()
    return create_access_token(user_id), raw


async def rotate_refresh(db: AsyncSession, raw_token: str) -> tuple[str, str]:
    row = await db.scalar(select(RefreshToken).where(RefreshToken.token_hash == sha256(raw_token)))
    if row is None:
        raise AppError("refresh_invalid", "Unknown refresh token", 401)
    if row.revoked:
        # Reuse of an already-rotated token -> revoke the whole chain for that user.
        await _revoke_all(db, row.user_id)
        raise AppError("refresh_reuse", "Refresh token reuse detected", 401)
    if _aware(row.expires_at) < _now():
        raise AppError("refresh_expired", "Refresh token expired", 401)

    access, new_raw = await _issue_pair(db, row.user_id)
    new_row = await db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == sha256(new_raw))
    )
    row.revoked = True
    row.replaced_by = new_row.id
    await db.flush()
    return access, new_raw


async def _revoke_all(db: AsyncSession, user_id: uuid.UUID) -> None:
    rows = await db.scalars(
        select(RefreshToken).where(RefreshToken.user_id == user_id, RefreshToken.revoked.is_(False))
    )
    for r in rows:
        r.revoked = True
    await db.flush()


async def logout(db: AsyncSession, raw_token: str) -> None:
    row = await db.scalar(select(RefreshToken).where(RefreshToken.token_hash == sha256(raw_token)))
    if row is not None:
        row.revoked = True
        await db.flush()
