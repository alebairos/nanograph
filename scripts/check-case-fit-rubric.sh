#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CASE-FIT-RUBRIC FAIL: $1" >&2; exit 1; }

SCORE="./scripts/score-case-fit.sh"
CASES="fixtures/fit-cases"

run() {
  OUT="$("$SCORE" "$1" 2>&1)" && RC=0 || RC=$?
}

echo "== case-fit gate: all four factors >= 1, criticality only scales priority =="

run "$CASES/utf8-overlong.fit"
[[ "$RC" -eq 0 ]] || fail "utf8-overlong expected exit 0, got $RC"
[[ "$OUT" == *"gate=FIT"* ]] || fail "utf8-overlong expected gate=FIT"
[[ "$OUT" == *"fit_score=8/8"* ]] || fail "utf8-overlong expected fit_score=8/8"
[[ "$OUT" == *"priority=8"* ]] || fail "utf8-overlong expected priority=8"

run "$CASES/payment-conservation.fit"
[[ "$RC" -eq 0 ]] || fail "payment-conservation expected exit 0, got $RC"
[[ "$OUT" == *"gate=FIT"* ]] || fail "payment-conservation expected gate=FIT"
[[ "$OUT" == *"priority=16"* ]] || fail "payment-conservation expected priority=16"

run "$CASES/dna-reverse-complement.fit"
[[ "$RC" -eq 0 ]] || fail "dna-reverse-complement expected exit 0, got $RC"
[[ "$OUT" == *"gate=FIT"* ]] || fail "dna-reverse-complement expected gate=FIT"

run "$CASES/robotics-control-loop.fit"
[[ "$RC" -eq 1 ]] || fail "robotics-control-loop expected exit 1, got $RC"
[[ "$OUT" == *"gate=NOT-A-FIT"* ]] || fail "robotics-control-loop expected gate=NOT-A-FIT"
[[ "$OUT" == *"zero_factors=observable"* ]] || fail "robotics-control-loop expected zero_factors=observable"

TMP_RANGE="$(mktemp -t fitrange.XXXXXX)"
TMP_MISS="$(mktemp -t fitmiss.XXXXXX)"
trap 'rm -f "$TMP_RANGE" "$TMP_MISS"' EXIT

cat > "$TMP_RANGE" <<'EOF'
name=oob
oracle_hardness=2
property_checkable=2
observable=5
silent_survival=2
criticality=1
relation=none
EOF
run "$TMP_RANGE"
[[ "$RC" -eq 2 ]] || fail "out-of-range observable=5 expected exit 2, got $RC"

cat > "$TMP_MISS" <<'EOF'
name=missing
oracle_hardness=2
property_checkable=2
observable=2
criticality=1
relation=none
EOF
run "$TMP_MISS"
[[ "$RC" -eq 2 ]] || fail "missing silent_survival expected exit 2, got $RC"

echo "CASE-FIT-RUBRIC OK: 4 scorecards scored, gate + poka-yoke verified"
