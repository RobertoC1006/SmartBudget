from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field


class BudgetCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    month: Optional[int] = Field(default=None, ge=1, le=12)
    year: Optional[int] = Field(default=None, ge=2000, le=2100)
    name: Optional[str] = Field(default=None, max_length=100)
    alert_threshold: Optional[float] = Field(default=None, ge=0, le=1)


class BudgetRead(BaseModel):
    id: str
    name: str
    month: int
    year: int
    amount: float
    currency: str
    spent: float
    remaining: float
    alert_threshold: float
    created_at: dt.datetime
    updated_at: dt.datetime

    class Config:
        from_attributes = True

