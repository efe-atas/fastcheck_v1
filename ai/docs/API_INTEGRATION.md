# FastAPI OCR Integration (Spring Boot -> FastAPI)

## Endpoint
- `POST /v1/ocr/exams:extract`

## Headers
- `Authorization: Bearer <service-jwt>`
- `Content-Type: application/json`
- `X-Request-Id: <optional-correlation-id>`
- `X-User-Id: <authenticated-user-id-from-spring-jwt>`

## Request Body
```json
{
  "image_url": "https://minio.local/bucket/exams/exam-001.png",
  "source_id": "exam-001",
  "language_hint": "tr"
}
```

## Response Body (200)
```json
{
  "request_id": "correlation-id",
  "result": {
    "document_type": "exam_paper",
    "language": "tr",
    "pages": [
      {
        "page_number": 1,
        "questions": [],
        "unmatched_text_blocks": []
      }
    ]
  }
}
```

## Error Mapping
- `401`: Missing/invalid JWT
- `422`: Invalid input or non-image URL content
- `502`: OCR upstream (LLM) failure

## Spring Boot Notes
- Use WebClient/RestTemplate with 20s timeout.
- Forward `X-Request-Id` for traceability.
- Extract `userId` from authenticated Spring Security context and forward as `X-User-Id`.
- Retry only on `502` and upstream network errors with short backoff.
