# Multi-stage build: install dependencies in a builder stage, copy only
# the installed packages into a small runtime image.
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN grep -v '^pytest' requirements.txt > runtime.txt \
 && pip install --no-cache-dir --prefix=/install -r runtime.txt

FROM python:3.12-slim
LABEL maintainer="Srishti Kainth <srishtikainth2@gmail.com>" \
      description="DevOps Lab 2 Flask app"
ENV PYTHONUNBUFFERED=1 DATA_DIR=/data
COPY --from=builder /install /usr/local
WORKDIR /app
COPY app.py .
RUN useradd --uid 10001 --no-create-home appuser \
 && mkdir -p /data && chown appuser /data
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=15s --timeout=3s CMD python -c "import urllib.request;urllib.request.urlopen('http://localhost:5000/healthz')"
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
