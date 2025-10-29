"""Detección y gestión de alertas financieras."""

from __future__ import annotations

from decimal import Decimal
from typing import Iterable, Sequence

from sqlalchemy.orm import Session

from Backend.core.config import get_settings
from Backend.core.enums import AlertSeverity, AlertType, ExpenseCategory
from Backend.db import models


def _remaining_ratio(budget: models.Budget) -> float:
    if budget.amount == 0:
        return 0.0
    remaining = Decimal(budget.remaining)
    amount = Decimal(budget.amount)
    return float(max(Decimal("0"), remaining) / amount)


def check_budget_alerts(db: Session, budget: models.Budget) -> list[models.Alert]:
    settings = get_settings()
    ratio = _remaining_ratio(budget)

    alerts: list[models.Alert] = []
    if ratio <= budget.alert_threshold:
        severity = AlertSeverity.CRITICAL if ratio <= 0.1 else AlertSeverity.WARNING
        message = f"Te queda {ratio * 100:.0f}% del presupuesto mensual."
        alerts.append(
            models.Alert(
                user_id=budget.user_id,
                budget_id=budget.id,
                alert_type=AlertType.PRESUPUESTO,
                severity=severity,
                title="Presupuesto cerca del límite",
                message=message,
            )
        )

    # Alerta de incremento en ocio
    ocio_expenses = [expense for expense in budget.expenses if expense.category is ExpenseCategory.OCIO]
    ocio_total = sum((expense.amount for expense in ocio_expenses), Decimal("0"))
    overall_total = sum((expense.amount for expense in budget.expenses), Decimal("0"))
    if overall_total > 0:
        ocio_ratio = float(ocio_total / overall_total)
        if ocio_ratio >= settings.alert_percentage_variation:
            alerts.append(
                models.Alert(
                    user_id=budget.user_id,
                    budget_id=budget.id,
                    alert_type=AlertType.CATEGORIA,
                    severity=AlertSeverity.WARNING,
                    title="Gasto en ocio elevado",
                    message="El gasto en ocio supera el 30% del total en este mes.",
                )
            )

    for alert in alerts:
        db.add(alert)
    if alerts:
        db.commit()
        for alert in alerts:
            db.refresh(alert)
    return alerts


def list_alerts(db: Session, user_id: str, include_acknowledged: bool = False) -> Sequence[models.Alert]:
    query = db.query(models.Alert).filter(models.Alert.user_id == user_id)
    if not include_acknowledged:
        query = query.filter(models.Alert.acknowledged.is_(False))
    return query.order_by(models.Alert.created_at.desc()).all()


def acknowledge_alert(db: Session, alert: models.Alert) -> models.Alert:
    alert.acknowledged = True
    alert.acknowledged_at = alert.acknowledged_at or alert.updated_at
    db.commit()
    db.refresh(alert)
    return alert

