"""Gestión centralizada de configuración para el backend."""

from __future__ import annotations

import pathlib
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    api_title: str = Field(default="SmartBudget+ API")
    api_version: str = Field(default="0.1.0")
    api_prefix: str = Field(default="/api")
    environment: str = Field(default="development")
    secret_key: str = Field(default="change-me")
    access_token_expire_minutes: int = Field(default=60 * 24)
    refresh_token_expire_minutes: int = Field(default=60 * 24 * 15)
    jwt_algorithm: str = Field(default="HS256")

    database_url: str = Field(default="sqlite:///./data/smartbudget.db")
    echo_sql: bool = Field(default=False)

    default_currency: str = Field(default="PEN")
    low_budget_threshold: float = Field(default=0.25)
    alert_percentage_variation: float = Field(default=0.3)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    def ensure_directories(self) -> None:
        """Crea carpetas necesarias para almacenamiento local."""
        if self.database_url.startswith("sqlite:///"):
            db_path = pathlib.Path(self.database_url.replace("sqlite:///", "", 1))
            if not db_path.is_absolute():
                db_path = pathlib.Path().resolve() / db_path
            db_path.parent.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.ensure_directories()
    return settings
