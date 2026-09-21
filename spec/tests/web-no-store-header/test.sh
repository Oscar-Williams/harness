#!/usr/bin/env bash
# web-no-store-header — every non-SSE response carries Cache-Control: no-store
# so mobile browsers never serve stale session pages from heuristic cache.
set -euo pipefail
source "${SPEC_DIR}/helpers.sh"
setup
source "${HARNESS_ROOT}/plugins/web/lib/http.sh"

STATUS=200
HEADERS=("Content-Type: text/html; charset=utf-8")
BODY="<html>dynamic session content</html>"
out="$(respond_request)"
printf '%s' "${out}" | grep -qi $'Cache-Control: no-store' \
  || { echo "FAIL: no-store missing"; printf '%s' "${out}" | od -c | head -5; exit 1; }
# framing still intact: body delivered after blank line
echo "${out}" | grep -qF '<html>dynamic session content</html>' || { echo "FAIL: body mangled"; exit 1; }
