#!/usr/bin/env bash
# smoke-test.sh — Basic HTTP smoke tests against a deployed app endpoint
# Usage: ./scripts/smoke-test.sh <base-url> [max-retries]

set -euo pipefail

BASE_URL="${1:?Usage: $0 <base-url>}"
MAX_RETRIES="${2:-10}"
RETRY_DELAY=10

echo "Running smoke tests against: $BASE_URL"

# ── Helper ────────────────────────────────────────────────────────────────────
check_endpoint() {
  local path="$1"
  local expected_status="${2:-200}"
  local url="${BASE_URL}${path}"
  local attempt=0

  echo -n "  Checking $url (expect $expected_status) ... "

  while [ $attempt -lt $MAX_RETRIES ]; do
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 10 \
      --retry 0 \
      "$url" 2>/dev/null || echo "000")

    if [ "$status" = "$expected_status" ]; then
      echo "OK ($status)"
      return 0
    fi

    attempt=$((attempt + 1))
    echo -n "  [attempt $attempt/$MAX_RETRIES] got $status, retrying in ${RETRY_DELAY}s ... "
    sleep $RETRY_DELAY
  done

  echo "FAILED (got $status after $MAX_RETRIES attempts)"
  return 1
}

# ── Tests ─────────────────────────────────────────────────────────────────────
echo ""
echo "=== Health Checks ==="
check_endpoint "/healthz"
check_endpoint "/ready"

echo ""
echo "=== Application Endpoints ==="
check_endpoint "/"
check_endpoint "/metrics" 200

echo ""
echo "=== Negative Tests ==="
check_endpoint "/nonexistent-path-12345" 404

echo ""
echo "All smoke tests passed!"
