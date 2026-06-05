#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PROBE-TRACE FAIL: $1" >&2; exit 1; }

make -C tools -s all

[[ -f fixtures/add_two_patched.trace.golden ]] || fail "missing golden"
got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe trace fixtures/add_two_patched.ngb >"$got"
diff -u fixtures/add_two_patched.trace.golden "$got" || fail "trace drift"

echo "PROBE-TRACE OK"
