from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from Backend.api.routes import alerts, auth, budgets, expenses, goals, simulator, smartscore
from Backend.core.config import get_settings
from Backend.db import models  # noqa: F401  # Import necesario para registrar los modelos
from Backend.db.base import Base
from Backend.db.session import engine


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.api_title, version=settings.api_version)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router, prefix=settings.api_prefix)
    app.include_router(budgets.router, prefix=settings.api_prefix)
    app.include_router(expenses.router, prefix=settings.api_prefix)
    app.include_router(goals.router, prefix=settings.api_prefix)
    app.include_router(alerts.router, prefix=settings.api_prefix)
    app.include_router(smartscore.router, prefix=settings.api_prefix)
    app.include_router(simulator.router, prefix=settings.api_prefix)

    @app.on_event("startup")
    def on_startup() -> None:
        Base.metadata.create_all(bind=engine)

    @app.get("/")
    def healthcheck() -> dict[str, str]:
        return {"message": "Bienvenido a SmartBudget+", "status": "ok"}

    return app


app = create_app()

