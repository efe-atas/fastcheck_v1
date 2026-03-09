import json

from openai import OpenAI

from app.core.settings import Settings
from app.services.schemas import JSON_SCHEMA


class LlmClient:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._client = OpenAI(
            base_url=settings.openrouter_base_url,
            api_key=settings.openrouter_api_key,
        )

    def extract_exam_json(self, messages: list[dict]) -> dict:
        response = self._client.chat.completions.create(
            model=self._settings.openrouter_model,
            temperature=0,
            messages=messages,
            response_format={"type": "json_schema", "json_schema": JSON_SCHEMA},
            extra_body={"reasoning": {"enabled": True}},
        )

        content = response.choices[0].message.content or ""
        text = content.strip()
        if not text:
            raise RuntimeError("empty model output")

        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            raise RuntimeError("model returned non-json content") from exc
