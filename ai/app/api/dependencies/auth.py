from dataclasses import dataclass

import jwt
from fastapi import Header, HTTPException, status

from app.core.settings import get_settings


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


def verify_service_jwt(authorization: str | None = Header(default=None)) -> ServicePrincipal:
    settings = get_settings()

    if not settings.service_jwt_required:
        return ServicePrincipal(subject="anonymous")

    if not settings.service_jwt_secret:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="jwt secret is not configured")

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing bearer token")

    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="empty bearer token")

    try:
        payload = _decode_with_secret(
            token=token,
            secret=settings.service_jwt_secret,
            issuer=settings.service_jwt_issuer,
            audience=settings.service_jwt_audience,
            algorithms=[algo.strip() for algo in settings.service_jwt_algorithms.split(",") if algo.strip()],
        )
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid token") from exc

    sub = str(payload.get("sub", "")).strip()
    if not sub:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing sub claim")

    return ServicePrincipal(subject=sub)
