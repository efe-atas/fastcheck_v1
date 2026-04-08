import json
import logging
import time

from openai import APIConnectionError, APIError, AuthenticationError, BadRequestError, OpenAI, RateLimitError

from app.core.settings import Settings
from app.services.schemas import JSON_SCHEMA

logger = logging.getLogger("app.ocr.llm")


class LlmClient:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._client = OpenAI(
            base_url=settings.openrouter_base_url,
            api_key=settings.openrouter_api_key,
        )

    def extract_exam_json(self, messages: list[dict], request_id: str = "no-request-id") -> dict:
        if not self._settings.openrouter_api_key.strip():
            logger.error("[req=%s] Stage 3/4 llm_extract aborted because OPENROUTER_API_KEY is missing", request_id)
            raise RuntimeError("OPENROUTER_API_KEY is missing")

        started_at = time.perf_counter()
        logger.info(
            "[req=%s] Stage 3/4 llm_extract start model=%s base_url=%s",
            request_id,
            self._settings.openrouter_model,
            self._settings.openrouter_base_url,
        )
        try:
            response = self._client.chat.completions.create(
                model=self._settings.openrouter_model,
                temperature=0,
                messages=messages,
                response_format={"type": "json_schema", "json_schema": JSON_SCHEMA},
                extra_body={"reasoning": {"enabled": True}},
            )
        except AuthenticationError as exc:
            logger.exception("[req=%s] Stage 3/4 llm_extract authentication failed", request_id)
            raise RuntimeError("OpenRouter authentication failed") from exc
        except RateLimitError as exc:
            logger.exception("[req=%s] Stage 3/4 llm_extract rate limited", request_id)
            raise RuntimeError("OpenRouter rate limit reached") from exc
        except BadRequestError as exc:
            logger.exception("[req=%s] Stage 3/4 llm_extract bad request", request_id)
            raise RuntimeError(f"OpenRouter bad request: {exc}") from exc
        except APIConnectionError as exc:
            logger.exception("[req=%s] Stage 3/4 llm_extract connection failed", request_id)
            raise RuntimeError("OpenRouter connection failed") from exc
        except APIError as exc:
            logger.exception("[req=%s] Stage 3/4 llm_extract API error", request_id)
            raise RuntimeError(f"OpenRouter API error: {exc}") from exc

        content = response.choices[0].message.content or ""
        text = content.strip()
        if not text:
            logger.error("[req=%s] Stage 3/4 llm_extract returned empty content", request_id)
            raise RuntimeError("empty model output")
        logger.info(
            "[req=%s] Stage 3/4 llm_extract completed elapsed_ms=%s content_chars=%s",
            request_id,
            round((time.perf_counter() - started_at) * 1000),
            len(text),
        )

        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            logger.exception(
                "[req=%s] Stage 3/4 llm_extract returned non-json content preview=%s",
                request_id,
                text[:300],
            )
            raise RuntimeError("model returned non-json content") from exc
