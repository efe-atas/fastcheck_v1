import logging
import socket
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

logger = logging.getLogger("app.ocr.fetcher")


class ImageFetchError(Exception):
    pass


def _detect_image_mime_from_bytes(data: bytes) -> str:
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith((b"GIF87a", b"GIF89a")):
        return "image/gif"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return ""


def fetch_image_bytes(url: str, timeout_seconds: int, max_bytes: int, request_id: str = "no-request-id") -> tuple[bytes, str]:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ImageFetchError("image_url must be http/https")

    req = Request(url, headers={"User-Agent": "fastcheck-ai-ocr/1.0"}, method="GET")
    logger.info(
        "[req=%s] Stage 1/4 fetch_image start host=%s path=%s timeout_seconds=%s max_bytes=%s",
        request_id,
        parsed.netloc,
        parsed.path,
        timeout_seconds,
        max_bytes,
    )
    try:
        with urlopen(req, timeout=timeout_seconds) as response:
            content_type = response.headers.get("Content-Type", "").split(";")[0].strip().lower()
            content_length = response.headers.get("Content-Length", "")
            logger.info(
                "[req=%s] Stage 1/4 fetch_image response status=%s content_type=%s content_length=%s",
                request_id,
                getattr(response, "status", "unknown"),
                content_type or "missing",
                content_length or "missing",
            )
            data = response.read(max_bytes + 1)
    except HTTPError as exc:
        logger.warning(
            "[req=%s] Stage 1/4 fetch_image HTTP error status=%s reason=%s url=%s",
            request_id,
            exc.code,
            exc.reason,
            url,
        )
        raise ImageFetchError(f"image fetch http error: {exc.code} {exc.reason}") from exc
    except URLError as exc:
        logger.warning("[req=%s] Stage 1/4 fetch_image URL error url=%s reason=%s", request_id, url, exc.reason)
        raise ImageFetchError(f"image fetch connection failed: {exc.reason}") from exc
    except TimeoutError as exc:
        logger.warning("[req=%s] Stage 1/4 fetch_image timeout url=%s", request_id, url)
        raise ImageFetchError("image fetch timed out") from exc
    except socket.timeout as exc:
        logger.warning("[req=%s] Stage 1/4 fetch_image socket timeout url=%s", request_id, url)
        raise ImageFetchError("image fetch timed out") from exc

    if len(data) > max_bytes:
        logger.warning("[req=%s] Stage 1/4 fetch_image exceeded max size bytes=%s", request_id, len(data))
        raise ImageFetchError("image exceeds max size")

    detected_mime = _detect_image_mime_from_bytes(data)
    mime_type = content_type
    if not mime_type.startswith("image/"):
        if detected_mime:
            mime_type = detected_mime
    if not mime_type.startswith("image/"):
        logger.warning(
            "[req=%s] Stage 1/4 fetch_image unsupported mime content_type=%s detected_mime=%s",
            request_id,
            content_type or "missing",
            detected_mime or "missing",
        )
        raise ImageFetchError("unsupported mime type")

    logger.info("[req=%s] Stage 1/4 fetch_image completed bytes=%s mime=%s", request_id, len(data), mime_type)
    return data, mime_type
