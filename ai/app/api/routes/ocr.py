import logging
import time
from uuid import uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.api.dependencies.auth import ServicePrincipal, verify_service_jwt
from app.core.settings import get_settings
from app.models.ocr_models import OcrExtractRequest, OcrExtractResponse
from app.services.llm_client import LlmClient
from app.services.ocr_service import OcrService
from app.services.storage_fetcher import ImageFetchError

router = APIRouter(prefix="/v1/ocr", tags=["ocr"])
logger = logging.getLogger("app.ocr.route")


@router.post("/exams:extract", response_model=OcrExtractResponse)
def extract_exam(
    payload: OcrExtractRequest,
    principal: ServicePrincipal = Depends(verify_service_jwt),
    x_request_id: str | None = Header(default=None),
    x_user_id: str | None = Header(default=None),
) -> OcrExtractResponse:
    settings = get_settings()
    request_id = x_request_id or str(uuid4())
    started_at = time.perf_counter()

    logger.info(
        "[req=%s] OCR request received subject=%s x_user_id=%s source_id=%s image_url=%s language_hint=%s",
        request_id,
        principal.subject,
        x_user_id,
        payload.source_id,
        payload.image_url,
        payload.language_hint,
    )

    try:
        service = OcrService(
            llm_client=LlmClient(settings),
            timeout_seconds=settings.image_fetch_timeout_seconds,
            max_bytes=settings.image_max_bytes,
        )
        result = service.extract_from_image_url(str(payload.image_url), request_id=request_id)
        elapsed_ms = round((time.perf_counter() - started_at) * 1000)
        logger.info(
            "[req=%s] OCR request completed successfully pages=%s elapsed_ms=%s",
            request_id,
            len(result.pages),
            elapsed_ms,
        )
        return OcrExtractResponse(request_id=request_id, result=result)
    except ImageFetchError as exc:
        elapsed_ms = round((time.perf_counter() - started_at) * 1000)
        logger.warning("[req=%s] OCR request failed during image fetch after %sms: %s", request_id, elapsed_ms, exc)
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except Exception as exc:
        elapsed_ms = round((time.perf_counter() - started_at) * 1000)
        logger.exception("[req=%s] OCR request failed after %sms", request_id, elapsed_ms)
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"ocr upstream failed: {exc}") from exc
