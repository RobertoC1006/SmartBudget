"""Funciones utilitarias de seguridad (hashing y JWT)."""

from __future__ import annotations

import datetime as dt
from typing import Any, Dict

from jose import jwt
from passlib.context import CryptContext

from Backend.core.config import get_settings


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(*, data: Dict[str, Any], expires_minutes: int) -> str:
    settings = get_settings()
    to_encode = data.copy()
    expire = dt.datetime.utcnow() + dt.timedelta(minutes=expires_minutes)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.jwt_algorithm)

