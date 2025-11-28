"""Servicios para metas y retos de ahorro."""

from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Iterable, Optional

from sqlalchemy.orm import Session

from core import expenses as expenses_service
from core.enums import ExpenseCategory, ExpenseSource, GoalStatus
from db import models


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
    increment = Decimal(str(amount))
    if increment <= 0:
        return goal
    goal.current_amount = (goal.current_amount + increment).quantize(Decimal("0.01"))
    if goal.current_amount >= goal.target_amount:
        goal.status = GoalStatus.ACHIEVED
    elif goal.current_amount > 0:
        goal.status = GoalStatus.IN_PROGRESS
    db.commit()
    db.refresh(goal)
    if increment > 0:
        expenses_service.create_expense(
            db,
            user=goal.user,
            description=f"Ahorro para {goal.name}",
            amount=increment,
            category=ExpenseCategory.OTROS,
            expense_date=dt.date.today(),
            source=ExpenseSource.ADJUSTMENT,
            extra_data={"goal_id": goal.id},
        )
        db.refresh(goal)
    return goal


def recommend_goals(user: models.User) -> list[str]:
    curated = [
        "Viaje a Colan con amigos.",
        "Fin de semana de playa o campo.",
        "Comprar ropa para la nueva temporada.",
        "Renovar laptop, tablet o celular.",
        "Fondo de emergencia de 3 meses.",
        "Curso o certificacion para crecer.",
        "Entradas para un concierto o festival.",
        "Mejorar la habitacion o sala de casa.",
    ]
    if user.monthly_income:
        curated.append(f"Separar S/{float(user.monthly_income) * 0.1:.2f} para imprevistos.")
    return curated


def get_goal(db: Session, goal_id: str, user_id: str) -> Optional[models.Goal]:
    return (
        db.query(models.Goal)
        .filter(models.Goal.id == goal_id, models.Goal.user_id == user_id)
        .first()
    )
