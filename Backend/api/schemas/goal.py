from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from Backend.core.enums import GoalStatus


class GoalCreate(BaseModel):
    name: str = Field(min_length=3, max_length=255)
    target_amount: Decimal = Field(gt=0)
    description: Optional[str] = Field(default=None, max_length=500)
    target_date: Optional[dt.date] = None


class GoalRead(BaseModel):
    id: str
    name: str
    description: Optional[str]
    target_amount: float
    current_amount: float
    target_date: Optional[dt.date]
    status: GoalStatus
    created_at: dt.datetime

    class Config:
        from_attributes = True

