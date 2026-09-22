import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app import rbac
from app.config import get_settings
from app.errors import AppError
from app.models.community import Community
from app.models.membership import Membership
from app.models.user import OtpChallenge, RefreshToken, User
from app.modules.identity.otp_adapter import get_sms_sender
from app.security import (
    code_matches,
    create_access_token,
    new_code,
    opaque_token,
    refresh_expiry,
    sha256,
    verify_password,
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

    # ponytail: fixed test code while OTP_DEBUG=true, so no SMS provider is needed yet.
    # Flip OTP_DEBUG=false (and set FAST2SMS_API_KEY) to switch to real random codes.
    code = "123456" if settings.otp_debug else new_code()
    db.add(
        OtpChallenge(
            mobile=mobile,
            code_hash=sha256(code),
            expires_at=_now() + timedelta(seconds=settings.otp_ttl_seconds),
        )
    )
    await db.flush()
    try:
        await get_sms_sender().send_otp(mobile, code)
    except Exception as exc:
        raise AppError("otp_send_failed", "Could not send the OTP, try again", 502) from exc
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


async def login_with_email(db: AsyncSession, email: str, password: str) -> tuple[User, str, str]:
    """Email+password login — the Super Admin's own sign-in path, separate
    from the phone-OTP flow every other role uses."""
    user = await db.scalar(select(User).where(User.email == email))
    # Compare against a well-formed dummy hash when the user doesn't exist so
    # verify_password still does real PBKDF2 work either way — no timing
    # signal that reveals whether the email exists.
    stored_hash = user.password_hash if user and user.password_hash else f"{'0' * 32}${'0' * 64}"
    if not verify_password(password, stored_hash) or user is None or not user.password_hash:
        raise AppError("invalid_credentials", "Incorrect email or password", 401)

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


async def list_my_memberships(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    """Every community membership the caller holds, with its effective
    capabilities (role's base caps + any extra granted ones) resolved —
    this is what a Committee Member's screen keys off (§1).
    """
    rows = await db.execute(
        select(Membership, Community.name)
        .join(Community, Community.id == Membership.community_id)
        .where(Membership.user_id == user_id)
        .order_by(Community.name)
    )
    return [
        {
            "id": m.id,
            "community_id": m.community_id,
            "community_name": name,
            "role": m.role,
            "status": m.status,
            "verification_status": m.verification_status,
            "unit_id": m.unit_id,
            "capabilities": sorted(rbac.effective_community_caps(m.role, m.capabilities)),
        }
        for m, name in rows.all()
    ]
