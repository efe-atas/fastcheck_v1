from urllib.parse import urlparse
from urllib.request import Request, urlopen


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


def fetch_image_bytes(url: str, timeout_seconds: int, max_bytes: int) -> tuple[bytes, str]:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ImageFetchError("image_url must be http/https")

    req = Request(url, headers={"User-Agent": "fastcheck-ai-ocr/1.0"}, method="GET")
    with urlopen(req, timeout=timeout_seconds) as response:
        content_type = response.headers.get("Content-Type", "").split(";")[0].strip().lower()
        data = response.read(max_bytes + 1)

    if len(data) > max_bytes:
        raise ImageFetchError("image exceeds max size")

    detected_mime = _detect_image_mime_from_bytes(data)
    mime_type = content_type
    if not mime_type.startswith("image/"):
        if detected_mime:
            mime_type = detected_mime
    if not mime_type.startswith("image/"):
        raise ImageFetchError("unsupported mime type")

    return data, mime_type
