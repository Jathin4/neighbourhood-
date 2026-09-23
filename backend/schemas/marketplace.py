import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ProviderProfileIn(BaseModel):
    business_name: str = Field(min_length=2, max_length=160)
    category: str = Field(min_length=2, max_length=60)


class ProviderProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    business_name: str
    category: str
    created_at: datetime
