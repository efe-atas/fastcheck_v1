from app.services.storage_fetcher import ImageFetchError, fetch_image_bytes


class _FakeHeaders:
    def __init__(self, content_type: str) -> None:
        self._content_type = content_type

    def get(self, key: str, default: str = "") -> str:
        if key.lower() == "content-type":
            return self._content_type
        return default


class _FakeResponse:
    def __init__(self, content_type: str, data: bytes) -> None:
        self.headers = _FakeHeaders(content_type)
        self._data = data

    def read(self, _: int) -> bytes:
        return self._data

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


def test_accepts_octet_stream_when_bytes_are_jpeg(monkeypatch):
    jpeg_bytes = b"\xff\xd8\xff\xe0" + b"fakejpeg"

    monkeypatch.setattr(
        "app.services.storage_fetcher.urlopen",
        lambda *_args, **_kwargs: _FakeResponse("application/octet-stream", jpeg_bytes),
    )

    data, mime_type = fetch_image_bytes(
        "http://127.0.0.1:8080/files/example.jpg",
        timeout_seconds=5,
        max_bytes=1024,
    )

    assert data == jpeg_bytes
    assert mime_type == "image/jpeg"


def test_rejects_non_image_payload_even_with_image_extension(monkeypatch):
    monkeypatch.setattr(
        "app.services.storage_fetcher.urlopen",
        lambda *_args, **_kwargs: _FakeResponse("application/octet-stream", b"{\"error\":\"forbidden\"}"),
    )

    try:
        fetch_image_bytes(
            "http://127.0.0.1:8080/files/example.jpg",
            timeout_seconds=5,
            max_bytes=1024,
        )
    except ImageFetchError as exc:
        assert str(exc) == "unsupported mime type"
        return

    raise AssertionError("Expected ImageFetchError for non-image payload")
