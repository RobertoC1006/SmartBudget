from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from Backend.core.enums import ExpenseCategory, ExpenseSource


class ExpenseCreate(BaseModel):
    description: str = Field(min_length=3, max_length=255)
    amount: Decimal = Field(gt=0)
    category: ExpenseCategory = Field(default=ExpenseCategory.GENERAL)
    expense_date: Optional[dt.date] = None
    currency: Optional[str] = Field(default=None, max_length=3)


class ExpenseRead(BaseModel):
    id: str
    description: str
    amount: float
    category: ExpenseCategory
    expense_date: dt.date
    currency: str
    source: ExpenseSource
    ocr_confidence: Optional[float] = None
    receipt_path: Optional[str] = None
    created_at: dt.datetime

    class Config:
        from_attributes = True


class OCRExpenseResponse(BaseModel):
    expense: ExpenseRead
    ocr_confidence: Optional[float]
    structured_data: dict

