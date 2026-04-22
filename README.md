# FastCheck

FastCheck is an education platform that digitizes exam workflows.

Teachers create classes and exams, upload exam papers, and trigger OCR extraction. Students and parents then track exam status and question details from the mobile app.

## Stack

- Backend: Spring Boot (Java 21, JWT, PostgreSQL/H2)
- OCR service: FastAPI (LLM-backed extraction, schema-validated JSON)
- Mobile: Flutter (BLoC + feature modules)
- Infra: Docker Compose + Nginx reverse proxy

## Repository Layout

```text
backend/fastcheck/   Spring Boot API
ai/                  FastAPI OCR microservice
frontend_mobile/     Flutter app
nginx/               Reverse proxy config
screenshots/         Product screenshots
docker-compose.yml   Full stack startup
```

## Quick Start

### Full stack with Docker

```bash
cp .env.example .env
docker compose up -d --build
```

Required secrets in `.env`:

- `POSTGRES_PASSWORD`
- `APP_JWT_SECRET`
- `FASTAPI_SERVICE_JWT_SECRET`
- `OPENROUTER_API_KEY`

Main routes:

- `/api/` -> Spring Boot
- `/ai/` -> FastAPI
- `/healthz` -> Nginx health

### Local development

Backend:

```bash
cd backend/fastcheck
./mvnw spring-boot:run
```

OCR service:

```bash
cd ai
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Mobile:

```bash
cd frontend_mobile
flutter pub get
flutter run
```

Default mobile API URL is `https://api.efeatas.dev/api`.
You can override with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api-host/api
```

## Core Features

- Role-based flows for `Admin`, `Teacher`, `Student`, and `Parent`
- Asynchronous OCR pipeline for uploaded exam images
- Exam status tracking and dashboard summaries
- Swagger/OpenAPI support on backend runtime
- Postman and Insomnia collections in backend docs

## Screenshots

<p align="center">
  <img src="screenshots/dashboard.PNG" width="340" alt="Dashboard" />
  <img src="screenshots/sınavlar.PNG" width="340" alt="Exams list" />
</p>

<p align="center">
  <img src="screenshots/sınav_kagıdı_detay.PNG" width="340" alt="Exam paper detail" />
  <img src="screenshots/sınav_soru_detay.PNG" width="340" alt="Exam question detail" />
</p>

<p align="center">
  <img src="screenshots/sınav_ogrencı_lıstesı.PNG" width="340" alt="Student list" />
  <img src="screenshots/ocr_lab_sayfası.PNG" width="340" alt="OCR lab" />
</p>

<p align="center">
  <img src="screenshots/ogretmen_soru_override.PNG" width="340" alt="Teacher override" />
</p>

## Docs

- `DEPLOYMENT.md`
- `ai/README.md`
- `ai/docs/API_INTEGRATION.md`
- `backend/fastcheck/README.md`
- `frontend_mobile/README.md`
