import base64
import logging
import time

from app.models.ocr_models import ExamPaperOutput
from app.services.llm_client import LlmClient
from app.services.prompts import AUTO_USER_PROMPT, SYSTEM_PROMPT
from app.services.storage_fetcher import fetch_image_bytes

logger = logging.getLogger("app.ocr.service")


class OcrService:
    def __init__(self, llm_client: LlmClient, timeout_seconds: int, max_bytes: int) -> None:
        self._llm_client = llm_client
        self._timeout_seconds = timeout_seconds
        self._max_bytes = max_bytes

    def extract_from_image_url(self, image_url: str, request_id: str = "no-request-id") -> ExamPaperOutput:
        started_at = time.perf_counter()
        image_bytes, mime_type = fetch_image_bytes(
            image_url,
            timeout_seconds=self._timeout_seconds,
            max_bytes=self._max_bytes,
            request_id=request_id,
        )
        logger.info("[req=%s] Stage 2/4 prepare_prompt start", request_id)
        data_url = f"data:{mime_type};base64,{base64.b64encode(image_bytes).decode('utf-8')}"
        logger.info(
            "[req=%s] Stage 2/4 prepare_prompt completed mime=%s image_bytes=%s data_url_chars=%s",
            request_id,
            mime_type,
            len(image_bytes),
            len(data_url),
        )

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": AUTO_USER_PROMPT},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ],
            },
        ]

        raw = self._llm_client.extract_exam_json(messages, request_id=request_id)
        logger.info("[req=%s] Stage 4/4 validate_output start", request_id)
        result = ExamPaperOutput.model_validate(raw)
        logger.info(
            "[req=%s] Stage 4/4 validate_output completed pages=%s total_elapsed_ms=%s",
            request_id,
            len(result.pages),
            round((time.perf_counter() - started_at) * 1000),
        )
        return result
