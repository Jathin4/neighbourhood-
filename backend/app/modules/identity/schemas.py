import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

MOBILE = Field(pattern=r"^\+?[1-9]\d{7,14}$", description="E.164-ish mobile number")


class OtpRequestIn(BaseModel):
    mobile: str = MOBILE


class OtpRequestOut(BaseModel):
    sent: bool = True
    expires_in: int
    debug_code: str | None = None


class OtpVerifyIn(BaseModel):
    mobile: str = MOBILE
    code: str = Field(min_length=4, max_length=8)


class RefreshIn(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mobile: str
    email: str | None
    name: str | None
    photo_url: str | None
    status: str
    platform_role: str | None
    preferences: dict
    created_at: datetime


class UserUpdateIn(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    email: EmailStr | None = None
    photo_url: str | None = Field(default=None, max_length=500)
    preferences: dict | None = None


class MyMembershipOut(BaseModel):
    """The caller's own membership, with the community name for display and
    the capabilities their role/membership actually grants (§1: capability-
    based, not UI-only role checks) — this is what drives what a Committee
    Member's screen shows.
    """

    id: uuid.UUID
    community_id: uuid.UUID
    community_name: str
    role: str
    status: str
    verification_status: str
    unit_id: uuid.UUID | None
    capabilities: list[str]
