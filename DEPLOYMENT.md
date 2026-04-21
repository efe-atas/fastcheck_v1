# Production Deployment

## Files

- `docker-compose.yml`: Spring Boot, FastAPI, nginx, and PostgreSQL
- `.env.example`: production environment template
- `nginx/nginx.conf`: reverse proxy for `/api/` and `/ai/`
- `/etc/cloudflared/config.yml`: public tunnel mapping for `api.efeatas.dev`

## Setup

1. Copy `.env.example` to `.env`.
2. Replace every placeholder secret with a real random value.
3. Set `OPENROUTER_API_KEY`.
4. Set `NGINX_PORT` to a free host port. The default and current working deployment use `8081`.
5. Confirm `APP_FILES_PUBLIC_BASE_URL` matches your public domain.
6. Confirm Flutter uses `https://api.efeatas.dev/api` as its base URL.
7. In `/etc/cloudflared/config.yml`, route `api.efeatas.dev` to `http://127.0.0.1:${NGINX_PORT}`.

## Start

```bash
docker compose up -d --build
```

If Docker requires elevated privileges on the host:

```bash
sudo docker compose up -d --build
```

If you change the tunnel target, restart `cloudflared`:

```bash
sudo systemctl restart cloudflared
```

## Persistent Data

- PostgreSQL data is stored in the named volume `postgres_data`.
- Uploaded files are stored in the named volume `uploads_data`.

## Routing

- `http://127.0.0.1:${NGINX_PORT}/api/` -> Spring Boot
- `http://127.0.0.1:${NGINX_PORT}/ai/` -> FastAPI
- `http://127.0.0.1:${NGINX_PORT}/healthz` -> nginx health response
- `https://api.efeatas.dev/api/` -> Spring Boot through `cloudflared`
- `https://api.efeatas.dev/ai/` -> FastAPI through `cloudflared`
- `https://api.efeatas.dev/healthz` -> public nginx health response

## Notes

- The backend talks to FastAPI over the internal Docker network using `http://fastapi:8000`.
- Backend file URLs should be published as `https://api.efeatas.dev/api/files/...`.
- Without changing the Flutter app, requests aimed at `https://api.efeatas.dev` will miss the `/api/` prefix and fail.
- If host port `80` or `8080` is already occupied, keep nginx on `8081` or another free port and point `cloudflared` at that port.
