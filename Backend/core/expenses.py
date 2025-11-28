"""Lógica de gestión de gastos."""

from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Iterable, Optional

from sqlalchemy import asc, desc
from sqlalchemy.orm import Session

from core import budgets as budgets_service
from core.enums import ExpenseCategory, ExpenseSource
from db import models


def _to_decimal(value: float | str | Decimal) -> Decimal:
    return Decimal(str(value)).quantize(Decimal("0.01"))


def create_expense(
    db: Session,
    *,
    user: models.User,
    description: str,
    amount: Decimal,
    category: ExpenseCategory,
    expense_date: dt.date,
    source: ExpenseSource,
    currency: str | None = None,
    extra_data: dict | None = None,
    receipt_path: str | None = None,
    ocr_confidence: float | None = None,
) -> models.Expense:
    expense = models.Expense(
        user_id=user.id,
        description=description,
        amount=_to_decimal(amount),
        category=category,
        expense_date=expense_date,
        source=source,
        currency=currency or user.default_currency,
        extra_data=extra_data,
        receipt_path=receipt_path,
        ocr_confidence=ocr_confidence,
    )
    db.add(expense)
    db.flush()
    budgets_service.attach_budget_to_expense(db, expense)
    db.commit()
    db.refresh(expense)
    if expense.budget:
        from core import alerts as alerts_service  # import interno para evitar ciclo

        alerts_service.check_budget_alerts(db, expense.budget)
        from core import smartscore as smartscore_service

        snapshot = smartscore_service.calculate_smartscore(db, user, budget=expense.budget)
        smartscore_service.generate_alerts_from_score(db, snapshot)
    return expense


def list_expenses(
    db: Session,
    *,
    user_id: str,
    skip: int = 0,
    limit: int = 50,
    budget_id: str | None = None,
    category: ExpenseCategory | None = None,
    sort_desc: bool = True,
) -> Iterable[models.Expense]:
    query = db.query(models.Expense).filter(models.Expense.user_id == user_id)
    if budget_id:
        query = query.filter(models.Expense.budget_id == budget_id)
    if category:
        query = query.filter(models.Expense.category == category)
    order_clause = desc(models.Expense.expense_date) if sort_desc else asc(models.Expense.expense_date)
    return query.order_by(order_clause).offset(skip).limit(limit).all()


def get_expense(db: Session, expense_id: str, user_id: str) -> Optional[models.Expense]:
    return (
        db.query(models.Expense)
        .filter(models.Expense.id == expense_id, models.Expense.user_id == user_id)
        .first()
    )


def delete_expense(db: Session, expense: models.Expense) -> None:
    budget = expense.budget
    db.delete(expense)
    if budget:
        budgets_service.recalculate_budget_balance(db, budget)
    db.commit()


