"""Entry point: the upstream FastAPI app plus Prometheus metrics on /metrics."""

from prometheus_fastapi_instrumentator import Instrumentator

from app.main import app

Instrumentator(excluded_handlers=["/metrics", "/health"]).instrument(app).expose(app, include_in_schema=False)
