"""Gestión centralizada de configuración para el backend."""

from __future__ import annotations

import pathlib
from functools import lru_cache

from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class StorageSettings(BaseModel):
    base_path: pathlib.Path = Field(default=pathlib.Path("storage"))
    receipts_subdir: str = Field(default="receipts")
    temp_subdir: str = Field(default="tmp")

    @property
    def receipts_path(self) -> pathlib.Path:
        return self.base_path / self.receipts_subdir

    @property
    def temp_path(self) -> pathlib.Path:
        return self.base_path / self.temp_subdir


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

    ocr_language: str = Field(default="spa")
    ocr_confidence_threshold: float = Field(default=0.65)
    ocr_enabled: bool = Field(default=True)
    tesseract_cmd: str | None = Field(default=None)
    storage: StorageSettings = Field(default_factory=StorageSettings)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    def ensure_directories(self) -> None:
        """Crea carpetas necesarias para almacenamiento local."""
        self.storage.base_path.mkdir(parents=True, exist_ok=True)
        self.storage.receipts_path.mkdir(parents=True, exist_ok=True)
        self.storage.temp_path.mkdir(parents=True, exist_ok=True)
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
