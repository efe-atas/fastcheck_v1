import logging

from fastapi import FastAPI

from app.api.routes.health import router as health_router
from app.api.routes.ocr import router as ocr_router
from app.core.settings import get_settings


def configure_logging() -> None:
    root_logger = logging.getLogger()
    if not root_logger.handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
        )
        return

    root_logger.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s")
    for handler in root_logger.handlers:
        handler.setFormatter(formatter)


def create_app() -> FastAPI:
    configure_logging()
    settings = get_settings()
    logger = logging.getLogger("app.main")
    app = FastAPI(title=settings.app_name, version="1.0.0")
    app.include_router(health_router)
    app.include_router(ocr_router)
    logger.info(
        "AI OCR service starting env=%s model=%s jwt_required=%s openrouter_key_present=%s jwt_secret_present=%s",
        settings.app_env,
        settings.openrouter_model,
        settings.service_jwt_required,
        bool(settings.openrouter_api_key.strip()),
        bool(settings.service_jwt_secret.strip() or settings.service_jwt_secret_alt.strip()),
    )
    return app


app = create_app()
