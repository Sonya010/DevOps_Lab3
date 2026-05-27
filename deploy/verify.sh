#!/bin/bash
set -euo pipefail

TARGET_HOST="${1:-localhost}"
BASE_URL="http://${TARGET_HOST}"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local url="$2"
  local expected_code="$3"
  local expected_body="${4:-}"

  response=$(curl -s -o /tmp/verify_body -w "%{http_code}" --max-time 10 "$url" || echo "000")

  if [ "$response" = "$expected_code" ]; then
    if [ -n "$expected_body" ] && ! grep -q "$expected_body" /tmp/verify_body; then
      echo "  FAIL [$desc] - code $response, body missing: $expected_body"
      FAIL=$((FAIL + 1))
    else
      echo "  PASS [$desc] - HTTP $response"
      PASS=$((PASS + 1))
    fi
  else
    echo "  FAIL [$desc] - expected HTTP $expected_code, got $response"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying deployment: $BASE_URL"

check "Nginx home page"    "$BASE_URL/"              "200" "Task Tracker"
check "Health alive"       "$BASE_URL/health/alive"  "200" "OK"
check "Health ready"       "$BASE_URL/health/ready"  "200" "OK"
check "GET /tasks"         "$BASE_URL/tasks"         "200"

NGINX_HEADER=$(curl -sI "$BASE_URL/" | grep -i "server:" | tr -d '\r')
if echo "$NGINX_HEADER" | grep -qi "nginx"; then
  echo "  PASS [Nginx server header]"
  PASS=$((PASS + 1))
else
  echo "  FAIL [Nginx server header] - not found in: $NGINX_HEADER"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "Result: PASS=$PASS  FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "Verification FAILED"
  exit 1
else
  echo "Verification PASSED"
  exit 0
fi
