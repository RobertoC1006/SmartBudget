"""Cálculo del SmartScore y recomendaciones asociadas."""

from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Iterable

from sqlalchemy.orm import Session

from core import budgets as budgets_service
from core.enums import AlertSeverity, AlertType, ExpenseCategory, SmartScoreBand
from db import models


def _band_from_score(score: int) -> SmartScoreBand:
    if score >= 70:
        return SmartScoreBand.GOOD
    if score >= 40:
        return SmartScoreBand.MODERATE
    return SmartScoreBand.RISKY


def _balance_penalty(budget: models.Budget) -> int:
    if budget.amount <= 0:
        return 30
    ratio = float(budget.spent / budget.amount)
    if ratio <= 0.5:
        return 0
    if ratio <= 0.75:
        return 10
    if ratio <= 0.9:
        return 25
    return 40


def _category_penalty(expenses: Iterable[models.Expense]) -> tuple[int, dict[str, float]]:
    summary = budgets_service.summarize_expenses_by_category(expenses)
    totals = {category.value: float(amount) for category, amount in summary.items()}
    ocio = summary.get(ExpenseCategory.OCIO, Decimal("0"))
    total = sum(summary.values(), Decimal("0"))
    if total == 0:
        return 0, totals
    ocio_ratio = float(ocio / total)
    if ocio_ratio <= 0.15:
        return 0, totals
    if ocio_ratio <= 0.25:
        return 5, totals
    return 12, totals


def _build_snapshot(user: models.User, budget: models.Budget, expenses: Iterable[models.Expense]) -> models.SmartScoreSnapshot:
    if budget.amount <= 0:
        raise ValueError("El presupuesto debe ser mayor a cero para calcular el SmartScore.")

    base_score = 100
    penalties = 0
    drivers: dict[str, float] = {}

    balance_penalty = _balance_penalty(budget)
    penalties += balance_penalty
    category_penalty, category_totals = _category_penalty(expenses)
    penalties += category_penalty

    drivers["balance_penalty"] = balance_penalty
    drivers["category_penalty"] = category_penalty
    drivers["spent_ratio"] = float(budget.spent / budget.amount) if budget.amount else 1.0
    drivers["category_totals"] = category_totals

    raw_score = max(0, base_score - penalties)
    band = _band_from_score(raw_score)

    if band is SmartScoreBand.GOOD:
        summary = "Salud financiera buena. Continúa con el ritmo actual."
    elif band is SmartScoreBand.MODERATE:
        summary = "Control moderado. Revisa tus gastos y ajusta para evitar llegar al límite."
    else:
        summary = "Necesitas controlar tus gastos. Ajusta categorías con más peso y reduce costos variables."

    return models.SmartScoreSnapshot(
        user_id=user.id,
        budget_id=budget.id,
        score=raw_score,
        band=band,
        summary=summary,
        drivers=drivers,
    )


def calculate_smartscore(
    db: Session,
    user: models.User,
    budget: models.Budget | None = None,
    *,
    persist: bool = True,
) -> models.SmartScoreSnapshot:
    budget = budget or budgets_service.get_budget_for_period(db, user.id)
    if budget is None:
        raise ValueError("El usuario no tiene un presupuesto activo para calcular SmartScore.")

    expenses = budget.expenses
    snapshot = _build_snapshot(user, budget, expenses)
    if persist:
        db.add(snapshot)
        db.commit()
        db.refresh(snapshot)
    return snapshot


def compute_snapshot(user: models.User, budget: models.Budget, expenses: Iterable[models.Expense] | None = None) -> models.SmartScoreSnapshot:
    expenses = expenses or budget.expenses
    return _build_snapshot(user, budget, expenses)


def generate_alerts_from_score(db: Session, snapshot: models.SmartScoreSnapshot) -> list[models.Alert]:
    if snapshot.band is SmartScoreBand.GOOD:
        return []
    severity = AlertSeverity.WARNING if snapshot.band is SmartScoreBand.MODERATE else AlertSeverity.CRITICAL
    message = (
        "Tu SmartScore está en nivel moderado, revisa tus categorías clave."
        if snapshot.band is SmartScoreBand.MODERATE
        else "Tu SmartScore está en rojo. Ajusta gastos de ocio y define un plan de ahorro urgente."
    )

    alert = models.Alert(
        user_id=snapshot.user_id,
        budget_id=snapshot.budget_id,
        alert_type=AlertType.SMARTSCORE,
        severity=severity,
        title="Alerta de SmartScore",
        message=message,
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return [alert]
