"""Utilidades para normalizar la salida de OCR y derivar campos relevantes."""

from __future__ import annotations

import datetime as dt
import re
from decimal import Decimal
from typing import Iterable

from Backend.core.enums import ExpenseCategory


DATE_PATTERNS: Iterable[re.Pattern[str]] = (
    re.compile(r"\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b"),
    re.compile(r"\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b"),
)

CURRENCY_SYMBOLS = {"$", "s/", "s/.", "usd", "pen", "€"}


CATEGORY_KEYWORDS: dict[ExpenseCategory, tuple[str, ...]] = {
    ExpenseCategory.ALIMENTACION: ("rest", "caf", "comid", "menu", "bar", "pan"),
    ExpenseCategory.TRANSPORTE: ("taxi", "bus", "uber", "gasolina", "combustible", "peaje"),
    ExpenseCategory.SERVICIOS: ("agua", "luz", "internet", "telefon", "servicio"),
    ExpenseCategory.SALUD: ("farmacia", "clinica", "hospital", "medic"),
    ExpenseCategory.EDUCACION: ("universidad", "colegio", "libro", "curso", "academ"),
    ExpenseCategory.OCIO: ("cine", "netflix", "spotify", "entreten"),
    ExpenseCategory.ROPA: ("ropa", "fashion", "vest", "polera", "jean"),
    ExpenseCategory.VIVIENDA: ("alquiler", "hipoteca", "departamento"),
}


def _normalize_text(text: str) -> str:
    sanitized = re.sub(r"[^\w\s\-/.,:]", " ", text, flags=re.UNICODE)
    sanitized = re.sub(r"\s+", " ", sanitized)
    return sanitized.strip().lower()


def _parse_date(text: str) -> dt.date | None:
    for pattern in DATE_PATTERNS:
        match = pattern.search(text)
        if not match:
            continue
        parts = [int(p) for p in match.groups()]
        if len(parts) == 3 and len(str(parts[0])) == 4:
            year, month, day = parts
        elif len(parts) == 3 and len(str(parts[2])) == 4:
            day, month, year = parts
        else:
            continue
        try:
            return dt.date(year, month, day)
        except ValueError:
            continue
    return None


def _parse_amount(text: str) -> Decimal | None:
    candidates = re.findall(r"(?:total|importe|monto|suma)[:\s]*([0-9]+[0-9.,]*)", text)
    if not candidates:
        candidates = re.findall(r"([0-9]+[0-9.,]{2,})", text)
    for candidate in reversed(candidates):
        cleaned = candidate.replace(" ", "").replace(",", ".")
        try:
            value = Decimal(cleaned)
        except Exception:
            continue
        if value > 0:
            return value.quantize(Decimal("0.01"))
    return None


def _infer_category(text: str) -> ExpenseCategory:
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in text for keyword in keywords):
            return category
    return ExpenseCategory.GENERAL


def estructurar_texto(texto_raw: str) -> dict:
    """Devuelve un diccionario con descripción, monto, fecha y categoría detectados."""
    normalized = _normalize_text(texto_raw)

    amount = _parse_amount(normalized)
    expense_date = _parse_date(normalized)
    category = _infer_category(normalized)

    descripcion = f"gasto en {category.value.replace('_', ' ')}"
    return {
        "descripcion": descripcion,
        # Usamos float para compatibilidad con JSON; mantenemos Decimal en capa de servicio.
        "monto": float(amount) if amount is not None else None,
        "fecha": expense_date.isoformat() if expense_date else None,
        "categoria": category.value,
        "texto_normalizado": normalized,
    }
