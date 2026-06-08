#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MANIFEST="${1:-}"
EXPECT_HEX="${2:-}"
LABEL="${3:-}"
[[ -n "$MANIFEST" && -n "$EXPECT_HEX" && -n "$LABEL" ]] || {
  echo "usage: check-backtest.sh <manifest> <expect_reject_hex> <label>" >&2
  exit 2
}

fail() { echo "BACKTEST-$LABEL FAIL: $1" >&2; exit 1; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "BACKTEST-$LABEL SKIP (no Linux runner)"
  exit 0
fi

[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST (run scripts/mint-backtest.sh)"
while IFS= read -r ngb; do
  [[ -f "$ngb" ]] || fail "missing $ngb (run scripts/mint-backtest.sh)"
done < <(sed -n 's/.*ngb=\([^ ]*\).*/\1/p' "$MANIFEST")

out="$(./scripts/backtest-relation.sh "$MANIFEST")" && rc=0 || rc=$?
echo "$out"

[[ "$rc" -eq 0 ]] || fail "timeline did not match every expect"
echo "$out" | grep -q "reject .*hex=$EXPECT_HEX" || fail "reject row must show hex=$EXPECT_HEX"
[[ "$(echo "$out" | grep -c "accept")" -eq 2 ]] || fail "expected two accept rows"

echo "BACKTEST-$LABEL OK: timeline accept -> reject ($EXPECT_HEX) -> accept"
