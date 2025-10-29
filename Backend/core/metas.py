"""Servicios para metas y retos de ahorro."""

from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Iterable, Optional

from sqlalchemy.orm import Session

from Backend.core.enums import GoalStatus
from Backend.db import models


def create_goal(
    db: Session,
    *,
    user: models.User,
    name: str,
    target_amount: Decimal,
    description: str | None = None,
    target_date: dt.date | None = None,
) -> models.Goal:
    goal = models.Goal(
        user_id=user.id,
        name=name,
        description=description,
        target_amount=Decimal(str(target_amount)),
        target_date=target_date,
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


def list_goals(db: Session, user_id: str) -> Iterable[models.Goal]:
    return (
        db.query(models.Goal)
        .filter(models.Goal.user_id == user_id)
        .order_by(models.Goal.created_at.desc())
        .all()
    )


def update_progress(db: Session, goal: models.Goal, amount: Decimal) -> models.Goal:
    goal.current_amount = Decimal(str(amount))
    if goal.current_amount >= goal.target_amount:
        goal.status = GoalStatus.ACHIEVED
    elif goal.current_amount > 0:
        goal.status = GoalStatus.IN_PROGRESS
    db.commit()
    db.refresh(goal)
    return goal


def recommend_goals(user: models.User) -> list[str]:
    suggestions = [
        "Ahorra el 15% de tus ingresos mensuales.",
        "Reduce los gastos de transporte en un 10%.",
        "Mantén tu SmartScore sobre 70 durante los próximos 3 meses.",
    ]
    if user.monthly_income:
        suggestions.append(f"Reserva S/{float(user.monthly_income) * 0.1:.2f} para un fondo de emergencia.")
    return suggestions


def get_goal(db: Session, goal_id: str, user_id: str) -> Optional[models.Goal]:
    return (
        db.query(models.Goal)
        .filter(models.Goal.id == goal_id, models.Goal.user_id == user_id)
        .first()
    )

