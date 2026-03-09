from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "fastcheck-ai-ocr"
    app_env: str = "dev"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_api_key: str = Field(default="", alias="OPENROUTER_API_KEY")
    openrouter_model: str = Field(default="google/gemini-3.1-flash-lite-preview", alias="OPENROUTER_MODEL")

    service_jwt_required: bool = True
    service_jwt_algorithms: str = "HS256"
    service_jwt_secret: str = ""
    service_jwt_jwks_url: str = ""
    service_jwt_issuer: str = "fastcheck-spring"
    service_jwt_audience: str = "fastcheck-ai"

    image_fetch_timeout_seconds: int = 20
    image_max_bytes: int = 12_000_000


@lru_cache
def get_settings() -> Settings:
    return Settings()
