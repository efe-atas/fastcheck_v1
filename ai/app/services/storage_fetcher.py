import mimetypes
from urllib.parse import urlparse
from urllib.request import Request, urlopen


class ImageFetchError(Exception):
    pass


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

    mime_type = content_type or mimetypes.guess_type(url)[0] or ""
    if not mime_type.startswith("image/"):
        raise ImageFetchError("unsupported mime type")

    return data, mime_type
