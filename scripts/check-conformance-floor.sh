#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CONFORMANCE-FLOOR FAIL: $1" >&2; exit 1; }

SPEC="fixtures/conformance/add_1_1.spec"

echo "== conformance floor (G9) =="
make -C tools -s bin/conf-eval bin/ngb-extract >/dev/null

[[ -f "$SPEC" ]] || fail "missing $SPEC"

echo "-- positive: add_two.ngb realizes add(1,1) --"
set +e
accept_out="$(./scripts/agent-eval/conformance-check.sh "$SPEC" fixtures/add_two.ngb)"
accept_code=$?
set -e
echo "$accept_out"
[[ "$accept_code" -eq 0 ]] || fail "expected accept for add_two.ngb"
[[ "$accept_out" == *"verdict=accept"* ]] || fail "missing accept verdict"

echo "-- negative: add_two_chain.ngb does not realize add(1,1) --"
set +e
reject_out="$(./scripts/agent-eval/conformance-check.sh "$SPEC" fixtures/add_two_chain.ngb)"
reject_code=$?
set -e
echo "$reject_out"
[[ "$reject_code" -eq 1 ]] || fail "expected reject (exit 1) for add_two_chain.ngb"
[[ "$reject_out" == *"verdict=reject"* ]] || fail "missing reject verdict"

echo "CONFORMANCE-FLOOR OK (accept add_two, reject add_two_chain)"
