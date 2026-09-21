#!/usr/bin/env bash
# web-watchdog-visible — the stream watchdog only reloads on foreground
# stalls: hidden tabs must not queue a reload for the moment of return.
set -euo pipefail
source "${SPEC_DIR}/helpers.sh"
setup
source "${HARNESS_ROOT}/plugins/web/lib/http.sh"
source "${HARNESS_ROOT}/plugins/web/lib/pages.sh"

out="$(_head "t" "t" </dev/null)"
echo "${out}" | grep -q "visibilitychange" || { echo "FAIL: no visibilitychange handler"; exit 1; }
echo "${out}" | grep -qF "!document.hidden && Date.now() - lastBeat > 45000" \
  || { echo "FAIL: watchdog not gated on visibility"; exit 1; }
