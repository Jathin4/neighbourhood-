import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.enums import CommunityRole, MembershipStatus


class CommunityIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    address: str | None = Field(default=None, max_length=500)
    settings: dict = Field(default_factory=dict)
    # Optional: when all three are set, units are auto-generated (§6 towers/blocks/units).
    towers: int = Field(default=0, ge=0, le=200)
    floors_per_tower: int = Field(default=0, ge=0, le=200)
    flats_per_floor: int = Field(default=0, ge=0, le=100)


class CommunityUpdateIn(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=160)
    address: str | None = Field(default=None, max_length=500)
    status: str | None = None
    settings: dict | None = None


class CommunityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    address: str | None
    status: str
    settings: dict
    created_at: datetime


class UnitIn(BaseModel):
    tower: str = Field(min_length=1, max_length=40)
    unit_number: str = Field(min_length=1, max_length=40)


class UnitBulkIn(BaseModel):
    units: list[UnitIn] = Field(min_length=1, max_length=2000)


class UnitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tower: str
    unit_number: str


class JoinRequestIn(BaseModel):
    unit_id: uuid.UUID | None = None
    household_relationship: str | None = Field(default=None, max_length=40)


class MembershipOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    community_id: uuid.UUID
    unit_id: uuid.UUID | None
    role: str
    status: str
    verification_status: str
    household_relationship: str | None
    capabilities: list
    created_at: datetime


class MembershipUpdateIn(BaseModel):
    status: MembershipStatus | None = None
    role: CommunityRole | None = None
    unit_id: uuid.UUID | None = None
    capabilities: list[str] | None = None


class ImportRowResult(BaseModel):
    row: int
    mobile: str | None = None
    outcome: str  # created | exists | error
    detail: str | None = None


class ImportSummary(BaseModel):
    total: int
    created: int
    existing: int
    errors: int
    results: list[ImportRowResult]
