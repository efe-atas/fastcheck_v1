## FastAPI OCR Service (for Spring Boot)

This service extracts exam paper content from an image URL and returns strict JSON.

### Run

```bash
cd ai
/Users/efeatas/Desktop/fastcheck/.venv/bin/pip install -r requirements.txt
cp .env.example .env
/Users/efeatas/Desktop/fastcheck/.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### API

- `GET /healthz`
- `POST /v1/ocr/exams:extract`

Example request:

```bash
curl -X POST "http://127.0.0.1:8000/v1/ocr/exams:extract" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SERVICE_JWT>" \
  -d '{
    "image_url": "https://example.com/exam.png",
    "source_id": "exam-001",
    "language_hint": "tr"
  }'
```

### Notes

- Service expects image URL from S3/MinIO (presigned URL recommended).
- JWT verification is required by default.
- OCR output schema is in `schemas/exam_paper_schema.json`.
