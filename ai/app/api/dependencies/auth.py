from dataclasses import dataclass
import logging

import jwt
from fastapi import Header, HTTPException, status

from app.core.settings import get_settings

logger = logging.getLogger("app.auth")


@dataclass
class ServicePrincipal:
    subject: str


def _decode_with_secret(token: str, secret: str, issuer: str, audience: str, algorithms: list[str]) -> dict:
    return jwt.decode(
        token,
        secret,
        algorithms=algorithms,
        issuer=issuer,
        audience=audience,
    )


def verify_service_jwt(
    authorization: str | None = Header(default=None),
    x_request_id: str | None = Header(default=None),
) -> ServicePrincipal:
    settings = get_settings()
    request_id = x_request_id or "no-request-id"

    if not settings.service_jwt_required:
        logger.info("[req=%s] auth skipped because service_jwt_required=false", request_id)
        return ServicePrincipal(subject="anonymous")

    primary_secret = settings.service_jwt_secret.strip()
    alt_secret = settings.service_jwt_secret_alt.strip()

    if not primary_secret and not alt_secret:
        logger.error("[req=%s] auth failed because no jwt secret is configured", request_id)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="jwt secret is not configured")

    if not authorization or not authorization.startswith("Bearer "):
        logger.warning("[req=%s] auth failed: missing bearer token", request_id)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing bearer token")

    token = authorization.split(" ", 1)[1].strip()
    if not token:
        logger.warning("[req=%s] auth failed: empty bearer token", request_id)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="empty bearer token")

    payload = None
    last_error: jwt.PyJWTError | None = None
    algorithms = [algo.strip() for algo in settings.service_jwt_algorithms.split(",") if algo.strip()]
    secrets = [("primary", primary_secret), ("alt", alt_secret)]
    for secret_label, secret in secrets:
        if not secret:
            continue
        try:
            payload = _decode_with_secret(
                token=token,
                secret=secret,
                issuer=settings.service_jwt_issuer,
                audience=settings.service_jwt_audience,
                algorithms=algorithms,
            )
            logger.info(
                "[req=%s] auth succeeded via %s secret subject=%s algorithms=%s",
                request_id,
                secret_label,
                payload.get("sub"),
                algorithms,
            )
            break
        except jwt.PyJWTError as exc:
            last_error = exc
            logger.warning(
                "[req=%s] auth decode failed via %s secret: %s: %s",
                request_id,
                secret_label,
                exc.__class__.__name__,
                exc,
            )
            continue

    if payload is None:
        logger.error(
            "[req=%s] auth failed after all secrets. last_error=%s",
            request_id,
            f"{last_error.__class__.__name__}: {last_error}" if last_error else "unknown",
        )
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid token")

    sub = str(payload.get("sub", "")).strip()
    if not sub:
        logger.error("[req=%s] auth failed: missing sub claim", request_id)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing sub claim")

    return ServicePrincipal(subject=sub)
