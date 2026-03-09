from fastapi import FastAPI

from app.api.routes.health import router as health_router
from app.api.routes.ocr import router as ocr_router
from app.core.settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.app_name, version="1.0.0")
    app.include_router(health_router)
    app.include_router(ocr_router)
    return app


app = create_app()
