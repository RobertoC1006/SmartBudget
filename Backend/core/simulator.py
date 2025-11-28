"""Simulador de escenarios '¿Y si...?'."""

from __future__ import annotations

import datetime as dt
from dataclasses import dataclass
from decimal import Decimal
from typing import Iterable

from sqlalchemy.orm import Session

from core import budgets as budgets_service
from core import smartscore as smartscore_service
from core.enums import ExpenseCategory, SimulationScenario
from db import models


@dataclass
class SimulationResult:
    projected_score: int
    band: str
    remaining_budget: float
    adjustments: dict[str, float]
    narrative: str


def run_simulation(
    db: Session,
    *,
    user: models.User,
    scenario: SimulationScenario,
    percentage: float | None = None,
    custom_adjustments: dict[str, float] | None = None,
) -> SimulationResult:
    budget = budgets_service.get_budget_for_period(db, user.id)
    if budget is None:
        raise ValueError("No existe un presupuesto activo para simular cambios.")

    adjustments: dict[str, float] = {}
    updated_spent = Decimal(budget.spent)

    if scenario is SimulationScenario.REDUCE_EXPENSES:
        pct = percentage or 10
        reduction = updated_spent * Decimal(pct / 100)
        updated_spent -= reduction
        adjustments["reduccion_gastos"] = float(reduction)
    elif scenario is SimulationScenario.INCREASE_SAVINGS:
        pct = percentage or 5
        extra_savings = Decimal(budget.amount) * Decimal(pct / 100)
        updated_spent -= extra_savings
        adjustments["ahorro_extra"] = float(extra_savings)
    elif scenario is SimulationScenario.CUSTOM and custom_adjustments:
        for category_name, pct in custom_adjustments.items():
            category = ExpenseCategory(category_name)
            category_total = sum(
                (expense.amount for expense in budget.expenses if expense.category == category),
                Decimal("0"),
            )
            reduction = category_total * Decimal(pct / 100)
            updated_spent -= reduction
            adjustments[f"{category.value}_ajuste"] = float(reduction)

    projected_remaining = Decimal(budget.amount) - updated_spent
    virtual_budget = models.Budget(
        user_id=user.id,
        name=budget.name,
        year=budget.year,
        month=budget.month,
        amount=budget.amount,
        currency=budget.currency,
        spent=updated_spent,
        remaining=projected_remaining,
        alert_threshold=budget.alert_threshold,
    )
    virtual_budget.expenses = budget.expenses  # type: ignore[assignment]

    snapshot = smartscore_service.compute_snapshot(user, virtual_budget, budget.expenses)

    narrative = (
        "Reduciendo gastos variables mejorarías tu SmartScore."
        if scenario is not SimulationScenario.INCREASE_SAVINGS
        else "Incrementar tu ahorro inmediato mejora el saldo disponible."
    )
    return SimulationResult(
        projected_score=snapshot.score,
        band=snapshot.band.value,
        remaining_budget=float(projected_remaining),
        adjustments=adjustments,
        narrative=narrative,
    )
