#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "NGB-PARSE-JSON FAIL: $1" >&2; exit 1; }

make -C tools -s bin/ngb-parse

got="$(tools/bin/ngb-parse --json fixtures/hello.ngb)"
echo "$got" | grep -q '"ok":true' || fail "hello not ok"
echo "$got" | grep -q 'graph_root_hash' || fail "missing hash"

bad="$(mktemp)"
printf 'NGB\x00' >"$bad"
trap 'rm -f "$bad"' EXIT
out="$(tools/bin/ngb-parse --json "$bad" 2>/dev/null || true)"
echo "$out" | grep -q '"ok":false' || fail "bad file should fail json"

echo "NGB-PARSE-JSON OK"
