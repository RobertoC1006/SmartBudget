"""Declarative base compartida entre los modelos ORM."""

from __future__ import annotations

from sqlalchemy.orm import DeclarativeBase, declared_attr


class Base(DeclarativeBase):
    """Declarative base que añade nombres de tabla automáticos."""

    @declared_attr.directive
    def __tablename__(cls) -> str:  # type: ignore[misc]
        return cls.__name__.lower()

