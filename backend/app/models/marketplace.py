import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base
from app.enums import BookingStatus
from app.models.base import PkMixin, TimestampMixin


class ProviderProfile(PkMixin, TimestampMixin, Base):
    """A user opts into being a service provider by having one of these."""

    __tablename__ = "provider_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True
    )
    business_name: Mapped[str] = mapped_column(String(160))
    category: Mapped[str] = mapped_column(String(60), index=True)


class Booking(PkMixin, TimestampMixin, Base):
    """A resident's service request. Unclaimed (provider_user_id is null)
    until a provider whose category matches accepts it — an open lead pool,
    not a pre-assigned job."""

    __tablename__ = "bookings"

    resident_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    provider_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    category: Mapped[str] = mapped_column(String(60), index=True)
    title: Mapped[str] = mapped_column(String(200))
    note: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default=BookingStatus.requested, index=True)
