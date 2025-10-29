"""Motor OCR con tolerancia a dependencias opcionales."""

from __future__ import annotations

import io
import logging
import pathlib
from dataclasses import dataclass
from typing import Iterable

from PIL import Image, ImageOps

from Backend.core.config import get_settings

try:  # pragma: no cover - dependencias opcionales
    import pytesseract  # type: ignore
except Exception:  # pragma: no cover
    pytesseract = None  # type: ignore

try:  # pragma: no cover - dependencias opcionales
    from pdf2image import convert_from_bytes  # type: ignore
except Exception:  # pragma: no cover
    convert_from_bytes = None  # type: ignore


logger = logging.getLogger(__name__)

settings = get_settings()

if pytesseract is not None:
    if settings.tesseract_cmd:
        pytesseract.pytesseract.tesseract_cmd = settings.tesseract_cmd
    else:
        possible_paths = [
            pathlib.Path("C:/Program Files/Tesseract-OCR/tesseract.exe"),
            pathlib.Path("C:/Program Files (x86)/Tesseract-OCR/tesseract.exe"),
            pathlib.Path("/usr/bin/tesseract"),
            pathlib.Path("/usr/local/bin/tesseract"),
        ]
        for candidate in possible_paths:
            if candidate.exists():
                pytesseract.pytesseract.tesseract_cmd = str(candidate)
                break


@dataclass
class OCRResult:
    text: str
    confidence: float | None
    engine: str


def _prepare_image(image: Image.Image) -> Image.Image:
    image = ImageOps.grayscale(image)
    image = ImageOps.autocontrast(image)
    return image


def _extract_from_images(images: Iterable[Image.Image]) -> OCRResult:
    settings = get_settings()
    if pytesseract is None:
        raise RuntimeError("pytesseract no está disponible en el entorno.")

    collected_text: list[str] = []
    confidences: list[float] = []
    for img in images:
        processed = _prepare_image(img)
        try:
            data = pytesseract.image_to_data(
                processed, lang=settings.ocr_language, output_type=pytesseract.Output.DICT
            )
            words = data.get("text", [])
            conf_values = data.get("conf", [])

            collected_text.append(" ".join(word for word in words if word))
            for conf in conf_values:
                try:
                    conf_float = float(conf)
                except (ValueError, TypeError):
                    continue
                if conf_float > -1:
                    confidences.append(conf_float / 100)
        except Exception as exc:  # pragma: no cover
            logger.exception("Error ejecutando pytesseract: %s", exc)
            raise

    confidence = sum(confidences) / len(confidences) if confidences else None
    return OCRResult(text="\n".join(collected_text).strip(), confidence=confidence, engine="pytesseract")


def read_file(path: pathlib.Path) -> OCRResult:
    """Ejecuta OCR sobre un archivo de imagen o PDF almacenado localmente."""
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        if convert_from_bytes is None:
            raise RuntimeError("pdf2image no está disponible para procesar PDF.")
        with path.open("rb") as file:
            images = convert_from_bytes(file.read())
        return _extract_from_images(images)

    with path.open("rb") as file:
        image = Image.open(io.BytesIO(file.read()))
        return _extract_from_images([image])


def read_bytes(filename: str, data: bytes) -> OCRResult:
    """Ejecuta OCR directamente sobre bytes obtenidos de una subida."""
    if pytesseract is None:
        raise RuntimeError("pytesseract no está disponible. Instala Tesseract OCR y reinicia la aplicación.")
    if not getattr(pytesseract.pytesseract, "tesseract_cmd", None):
        raise RuntimeError(
            "No se encontró el ejecutable de Tesseract. Instálalo y configura TESSERACT_CMD en el entorno o .env."
        )
    suffix = pathlib.Path(filename).suffix.lower()
    if suffix == ".pdf":
        if convert_from_bytes is None:
            raise RuntimeError("pdf2image no está disponible para procesar PDF.")
        images = convert_from_bytes(data)
    else:
        image = Image.open(io.BytesIO(data))
        images = [image]
    return _extract_from_images(images)
