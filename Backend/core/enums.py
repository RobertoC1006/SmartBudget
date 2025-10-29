"""Enumeraciones centrales utilizadas en la lógica de negocio."""

from __future__ import annotations

import enum


class ExpenseSource(str, enum.Enum):
    MANUAL = "manual"
    OCR = "ocr"
    ADJUSTMENT = "adjustment"


class ExpenseCategory(str, enum.Enum):
    GENERAL = "general"
    VIVIENDA = "vivienda"
    ALIMENTACION = "alimentacion"
    TRANSPORTE = "transporte"
    SERVICIOS = "servicios"
    SALUD = "salud"
    EDUCACION = "educacion"
    OCIO = "ocio"
    ROPA = "ropa"
    OTROS = "otros"


class AlertType(str, enum.Enum):
    PRESUPUESTO = "presupuesto"
    CATEGORIA = "categoria"
    SMARTSCORE = "smartscore"
    METAS = "metas"


class AlertSeverity(str, enum.Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class GoalStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    ACHIEVED = "achieved"
    MISSED = "missed"


class SmartScoreBand(str, enum.Enum):
    GOOD = "good"
    MODERATE = "moderate"
    RISKY = "risky"


class SimulationScenario(str, enum.Enum):
    REDUCE_EXPENSES = "reduce_expenses"
    INCREASE_SAVINGS = "increase_savings"
    CUSTOM = "custom"

