#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PROBE-DIFF FAIL: $1" >&2; exit 1; }

echo "== nano-probe diff proof =="

make -C tools -s all

[[ -f fixtures/add_two.diff.golden ]] || fail "missing fixtures/add_two.diff.golden"
[[ -f fixtures/add_two.ngb ]] || fail "missing fixtures/add_two.ngb"
[[ -f fixtures/add_two_patched.ngb ]] || fail "missing fixtures/add_two_patched.ngb"

got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe diff fixtures/add_two.ngb fixtures/add_two_patched.ngb >"$got"
diff -u fixtures/add_two.diff.golden "$got" || fail "diff stdout drift"

echo "PROBE-DIFF OK"
