import base64

from app.models.ocr_models import ExamPaperOutput
from app.services.llm_client import LlmClient
from app.services.prompts import AUTO_USER_PROMPT, SYSTEM_PROMPT
from app.services.storage_fetcher import fetch_image_bytes


class OcrService:
    def __init__(self, llm_client: LlmClient, timeout_seconds: int, max_bytes: int) -> None:
        self._llm_client = llm_client
        self._timeout_seconds = timeout_seconds
        self._max_bytes = max_bytes

    def extract_from_image_url(self, image_url: str) -> ExamPaperOutput:
        image_bytes, mime_type = fetch_image_bytes(
            image_url,
            timeout_seconds=self._timeout_seconds,
            max_bytes=self._max_bytes,
        )
        data_url = f"data:{mime_type};base64,{base64.b64encode(image_bytes).decode('utf-8')}"

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

        raw = self._llm_client.extract_exam_json(messages)
        return ExamPaperOutput.model_validate(raw)
