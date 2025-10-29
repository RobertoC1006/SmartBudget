"""Gestión de almacenamiento local para archivos subidos."""

from __future__ import annotations

import pathlib
import uuid

from Backend.core.config import get_settings


def save_receipt_file(data: bytes, original_name: str) -> pathlib.Path:
    settings = get_settings()
    extension = pathlib.Path(original_name).suffix or ".dat"
    filename = f"{uuid.uuid4().hex}{extension}"
    target_path = settings.storage.receipts_path / filename
    target_path.write_bytes(data)
    return target_path


def delete_file(path: pathlib.Path) -> None:
    if path.exists():
        path.unlink()

