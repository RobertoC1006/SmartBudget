"""Modelos ORM principales para SmartBudget+."""

from __future__ import annotations

import datetime as dt
import uuid
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from Backend.core.enums import AlertSeverity, AlertType, ExpenseCategory, ExpenseSource, GoalStatus, SmartScoreBand
from Backend.db.base import Base


UUID_STR = String(36)


class TimestampMixin:
    created_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    default_currency: Mapped[str] = mapped_column(String(3), default="PEN", nullable=False)
    monthly_income: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    budgets: Mapped[list["Budget"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    expenses: Mapped[list["Expense"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    goals: Mapped[list["Goal"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    alerts: Mapped[list["Alert"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    smartscore_history: Mapped[list["SmartScoreSnapshot"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class Budget(Base, TimestampMixin):
    __tablename__ = "budgets"
    __table_args__ = (UniqueConstraint("user_id", "year", "month", name="uq_budget_user_period"),)

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), default="Presupuesto mensual", nullable=False)
    year: Mapped[int] = mapped_column(nullable=False)
    month: Mapped[int] = mapped_column(nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    spent: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    remaining: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    alert_threshold: Mapped[float] = mapped_column(default=0.25, nullable=False)

    user: Mapped[User] = relationship(back_populates="budgets")
    expenses: Mapped[list["Expense"]] = relationship(back_populates="budget", cascade="all, delete-orphan")
    alerts: Mapped[list["Alert"]] = relationship(back_populates="budget", cascade="all, delete-orphan")
    smartscore_snapshots: Mapped[list["SmartScoreSnapshot"]] = relationship(
        back_populates="budget", cascade="all, delete-orphan"
    )


class Expense(Base, TimestampMixin):
    __tablename__ = "expenses"

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    budget_id: Mapped[str | None] = mapped_column(ForeignKey("budgets.id"), nullable=True, index=True)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[ExpenseCategory] = mapped_column(Enum(ExpenseCategory), default=ExpenseCategory.GENERAL)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    expense_date: Mapped[dt.date] = mapped_column(Date, default=dt.date.today, nullable=False)
    source: Mapped[ExpenseSource] = mapped_column(Enum(ExpenseSource), default=ExpenseSource.MANUAL)
    extra_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    receipt_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    ocr_confidence: Mapped[float | None] = mapped_column(nullable=True)

    user: Mapped[User] = relationship(back_populates="expenses")
    budget: Mapped[Budget | None] = relationship(back_populates="expenses")


class Goal(Base, TimestampMixin):
    __tablename__ = "goals"

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    current_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    target_date: Mapped[dt.date | None] = mapped_column(Date, nullable=True)
    status: Mapped[GoalStatus] = mapped_column(Enum(GoalStatus), default=GoalStatus.PENDING, nullable=False)

    user: Mapped[User] = relationship(back_populates="goals")


class Alert(Base, TimestampMixin):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    budget_id: Mapped[str | None] = mapped_column(ForeignKey("budgets.id"), nullable=True)
    alert_type: Mapped[AlertType] = mapped_column(Enum(AlertType), nullable=False)
    severity: Mapped[AlertSeverity] = mapped_column(Enum(AlertSeverity), default=AlertSeverity.WARNING, nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    acknowledged_at: Mapped[dt.datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped[User] = relationship(back_populates="alerts")
    budget: Mapped[Budget | None] = relationship(back_populates="alerts")


class SmartScoreSnapshot(Base, TimestampMixin):
    __tablename__ = "smartscore_snapshots"

    id: Mapped[str] = mapped_column(UUID_STR, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    budget_id: Mapped[str | None] = mapped_column(ForeignKey("budgets.id"), nullable=True)
    score: Mapped[int] = mapped_column(nullable=False)
    band: Mapped[SmartScoreBand] = mapped_column(Enum(SmartScoreBand), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    drivers: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    user: Mapped[User] = relationship(back_populates="smartscore_history")
    budget: Mapped[Budget | None] = relationship(back_populates="smartscore_snapshots")
