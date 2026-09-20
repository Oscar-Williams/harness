#!/usr/bin/env bash
# read-shadow-tag — repo-local read_file shadow prepends a tag= header on
# successful reads (the snapshot tag edit_file v2 verifies) and passes
# schema/describe/errors through unchanged.
set -euo pipefail
source "${SPEC_DIR}/helpers.sh"
setup

shadow="${HARNESS_ROOT}/.harness/tools/read_file"
core="${HARNESS_ROOT}/plugins/core/tools/read_file"
[[ -x "${shadow}" ]] || { echo "FAIL: ${shadow} missing"; exit 1; }
export HARNESS_CWD="${_tmpdir}"

printf 'hello\nworld\n' > "${_tmpdir}/t.txt"

# 1. successful read: first line is tag=<md5-8>
out="$(echo '{"path":"t.txt"}' | "${shadow}" --exec)" || { echo "$out"; exit 1; }
first="$(head -1 <<< "$out")"
assert_eq "tag header" "${first%%=*}" "tag"
assert_eq "tag value is md5-8" "${first#tag=}" "$(md5sum "${_tmpdir}/t.txt" | cut -c1-8)"
assert_eq "content follows" "$(sed -n '2p' <<< "$out" | cut -d: -f2-)" "hello"

# 2. error passthrough: no tag line, exit 1
out="$(echo '{"path":"missing.txt"}' | "${shadow}" --exec 2>&1)" && {
  echo "FAIL: missing file should error"; exit 1
}
echo "$out" | grep -q '^tag=' && { echo "FAIL: tag on error output"; exit 1; }
echo "$out" | grep -q 'file not found' || { echo "FAIL: no core error text"; exit 1; }

# 3. schema passthrough identical to core (plus nothing extra)
diff <("${shadow}" --schema) <("${core}" --schema) >/dev/null \
  || { echo "FAIL: schema diverges from core"; exit 1; }