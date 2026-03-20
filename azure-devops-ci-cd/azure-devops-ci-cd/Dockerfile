# Multi-stage build — keeps final image small and secure
# Stage 1: Build
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt* ./
RUN pip install --user --no-cache-dir -r requirements.txt 2>/dev/null || true

# Stage 2: Runtime
FROM python:3.12-slim AS runtime

# Security: run as non-root
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/sh --create-home appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appgroup app/ ./app/

USER appuser

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8080

# Labels for traceability
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.source="https://github.com/alilihic/azure-devops-ci-cd"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

CMD ["python", "-m", "app.main"]
