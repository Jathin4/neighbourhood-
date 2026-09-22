import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class BookingIn(BaseModel):
    category: str = Field(min_length=2, max_length=60)
    title: str = Field(min_length=2, max_length=200)
    note: str | None = Field(default=None, max_length=2000)


class BookingActionIn(BaseModel):
    action: Literal["accept", "complete", "cancel"]


class BookingOut(BaseModel):
    id: uuid.UUID
    resident_user_id: uuid.UUID
    provider_user_id: uuid.UUID | None
    category: str
    title: str
    note: str | None
    status: str
    created_at: datetime
    resident_name: str
    provider_name: str | None
