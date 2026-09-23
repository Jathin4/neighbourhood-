import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class IssueIn(BaseModel):
    community_id: uuid.UUID
    category: str = Field(min_length=1, max_length=60)
    title: str = Field(min_length=2, max_length=200)


class IssueActionIn(BaseModel):
    action: Literal["start", "resolve", "reopen"]


class IssueOut(BaseModel):
    id: uuid.UUID
    community_id: uuid.UUID
    raised_by: uuid.UUID
    raised_by_name: str
    category: str
    title: str
    status: str
    created_at: datetime
