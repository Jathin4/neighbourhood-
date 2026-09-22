import uuid
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base
from app.enums import AccountStatus
from app.models.base import PkMixin, TimestampMixin


class User(PkMixin, TimestampMixin, Base):
    __tablename__ = "users"

    # Nullable: email+password accounts (Super Admin) have no phone number.
    mobile: Mapped[str | None] = mapped_column(String(20), unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    # Set only for email+password accounts; OTP accounts never have one.
    password_hash: Mapped[str | None] = mapped_column(String(200))
    name: Mapped[str | None] = mapped_column(String(120))
    photo_url: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(20), default=AccountStatus.pending)
    # None for ordinary residents; set for platform staff.
    platform_role: Mapped[str | None] = mapped_column(String(20))
    preferences: Mapped[dict] = mapped_column(JSON, default=dict)


class OtpChallenge(PkMixin, TimestampMixin, Base):
    __tablename__ = "otp_challenges"

    mobile: Mapped[str] = mapped_column(String(20), index=True)
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    consumed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class RefreshToken(PkMixin, TimestampMixin, Base):
    __tablename__ = "refresh_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    # Set to the id of the token that replaced this one (rotation / reuse detection).
    replaced_by: Mapped[uuid.UUID | None] = mapped_column()
