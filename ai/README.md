## FastAPI OCR Service (for Spring Boot)

This service extracts exam paper content from an image URL and returns strict JSON.

### Run

```bash
cd ai
/Users/efeatas/Desktop/fastcheck/.venv/bin/pip install -r requirements.txt
cp .env.example .env
/Users/efeatas/Desktop/fastcheck/ai/.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```



╰─ source .venv/bin/activate                                                                                                                   ─╯
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
source: no such file or directory: .venv/bin/activate
INFO:     Will watch for changes in these directories: ['/Users/efeatas/Desktop/Projects/fastcheck/ai']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [62994] using WatchFiles
INFO:     Started server process [62996]
INFO:     Waiting for application startup.
INFO:     Application startup complete.

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
