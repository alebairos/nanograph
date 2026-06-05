#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "AUDIT-LOG FAIL: $1" >&2; exit 1; }

make -C tools -s bin/nano-probe
[[ -f fixtures/hello.audit-log.golden ]] || fail "missing fixtures/hello.audit-log.golden"

got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe audit-log fixtures/hello.ngb >"$got"
diff -u fixtures/hello.audit-log.golden "$got" || fail "audit-log stdout drift"
echo "OK: probe audit-log matches golden"
