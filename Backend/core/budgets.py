"""Servicios relacionados con presupuestos mensuales."""

from __future__ import annotations

import calendar
import datetime as dt
from decimal import Decimal
from typing import Iterable, Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from core.config import get_settings
from core.enums import ExpenseCategory
from db import models


def _current_period(ref: dt.date | None = None) -> tuple[int, int]:
    today = ref or dt.date.today()
    return today.year, today.month


def get_budget_for_period(
    db: Session, user_id: str, *, year: int | None = None, month: int | None = None
) -> Optional[models.Budget]:
    if year is None or month is None:
        year, month = _current_period()
    return (
        db.query(models.Budget)
        .filter(models.Budget.user_id == user_id, models.Budget.year == year, models.Budget.month == month)
        .first()
    )


def create_or_update_budget(
    db: Session,
    user: models.User,
    *,
    amount: Decimal,
    month: int | None = None,
    year: int | None = None,
    name: str | None = None,
    alert_threshold: float | None = None,
) -> models.Budget:
    amount = Decimal(str(amount)).quantize(Decimal("0.01"))
    year = year or dt.date.today().year
    month = month or dt.date.today().month

    budget = get_budget_for_period(db, user.id, year=year, month=month)
    if budget is None:
        budget = models.Budget(
            user_id=user.id,
            name=name or f"Presupuesto {calendar.month_name[month]} {year}",
            year=year,
            month=month,
            amount=amount,
            currency=user.default_currency,
            alert_threshold=alert_threshold or get_settings().low_budget_threshold,
        )
        db.add(budget)
    else:
        budget.amount = amount
        if name:
            budget.name = name
        if alert_threshold is not None:
            budget.alert_threshold = alert_threshold

    db.flush()
    recalculate_budget_balance(db, budget)
    db.commit()
    db.refresh(budget)
    return budget


def recalculate_budget_balance(db: Session, budget: models.Budget) -> None:
    spent_total: Decimal = (
        db.query(func.coalesce(func.sum(models.Expense.amount), 0))
        .filter(models.Expense.budget_id == budget.id)
        .scalar()
    )
    budget.spent = Decimal(spent_total or 0).quantize(Decimal("0.01"))
    budget.remaining = (budget.amount - budget.spent).quantize(Decimal("0.01"))


def attach_budget_to_expense(db: Session, expense: models.Expense) -> None:
    if expense.budget_id:
        return
    budget = get_budget_for_period(
        db,
        expense.user_id,
        year=expense.expense_date.year,
        month=expense.expense_date.month,
    )
    if budget is None:
        budget = get_budget_for_period(db, expense.user_id)
    if budget:
        expense.budget_id = budget.id
        db.flush()
        recalculate_budget_balance(db, budget)


def summarize_expenses_by_category(
    expenses: Iterable[models.Expense],
) -> dict[ExpenseCategory, Decimal]:
    summary: dict[ExpenseCategory, Decimal] = {}
    for expense in expenses:
        summary.setdefault(expense.category, Decimal("0.00"))
        summary[expense.category] += Decimal(expense.amount)
    return summary
