from __future__ import annotations

import datetime as dt

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from api.dependencies import get_current_user
from api.schemas import expense as expense_schema
from core import expenses as expenses_service
from core.enums import ExpenseCategory, ExpenseSource
from db import models
from db.session import get_db


router = APIRouter(prefix="/expenses", tags=["Gastos"])


@router.post("/", response_model=expense_schema.ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_manual_expense(
    payload: expense_schema.ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    expense_date = payload.expense_date or dt.date.today()
    source = payload.source or ExpenseSource.MANUAL
    currency = payload.currency or current_user.default_currency
    extra_data = payload.extra_data or None
    expense = expenses_service.create_expense(
        db,
        user=current_user,
        description=payload.description,
        amount=payload.amount,
        category=payload.category,
        expense_date=expense_date,
        source=source,
        currency=currency,
        extra_data=extra_data,
        ocr_confidence=payload.ocr_confidence,
    )
    return expense


@router.get("/", response_model=list[expense_schema.ExpenseRead])
def list_my_expenses(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
    category: ExpenseCategory | None = None,
):
    expenses = expenses_service.list_expenses(
        db,
        user_id=current_user.id,
        category=category,
    )
    return list(expenses)

