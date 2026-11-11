# syntax=docker/dockerfile:1.7
# Builds rest-api-transport-firm at a pinned commit and adds a /metrics endpoint (no fork of the app).
FROM python:3.13-slim

ARG APP_REPO=https://github.com/DYyyyDYyy/rest-api-transport-firm.git
ARG APP_REF
ADD --keep-git-dir=false ${APP_REPO}#${APP_REF} /src

WORKDIR /src
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN pip install -r requirements.txt prometheus-fastapi-instrumentator==8.1.0
COPY metrics_main.py /src/metrics_main.py

USER 10001:10001
EXPOSE 8000
CMD ["uvicorn", "metrics_main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
