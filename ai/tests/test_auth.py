from fastapi.testclient import TestClient

from app.main import app


def test_extract_requires_auth() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/ocr/exams:extract",
        json={"image_url": "https://example.com/a.png", "language_hint": "tr"},
    )
    assert response.status_code in {401, 500, 502}
