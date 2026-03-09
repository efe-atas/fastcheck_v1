#!/usr/bin/env python3
import json
import os
import sys
from urllib import error, request


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python3 gemini_image_chat.py <image-url>")
        return 1

    api_url = os.getenv("FASTAPI_OCR_URL", "http://127.0.0.1:8000/v1/ocr/exams:extract")
    token = os.getenv("SERVICE_JWT", "")

    payload = {
        "image_url": sys.argv[1],
        "source_id": "manual-cli",
        "language_hint": "tr",
    }

    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    req = request.Request(
        api_url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=60) as response:
            print(response.read().decode("utf-8"))
    except error.HTTPError as http_err:
        details = http_err.read().decode("utf-8", errors="replace")
        print(f"HTTP {http_err.code}: {details}")
        return 1
    except Exception as exc:  # noqa: BLE001
        print(f"Request failed: {exc}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
