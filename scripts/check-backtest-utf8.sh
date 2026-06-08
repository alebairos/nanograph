#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "BACKTEST-UTF8 FAIL: $1" >&2; exit 1; }

if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "BACKTEST-UTF8 SKIP (no Linux runner)"
  exit 0
fi

MANIFEST="fixtures/backtest/utf8/timeline.manifest"
[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST (run scripts/mint-backtest-utf8.sh)"
for f in utf8_rev1 utf8_rev2 utf8_rev3; do
  [[ -f "fixtures/backtest/utf8/$f.ngb" ]] || fail "missing $f.ngb (run scripts/mint-backtest-utf8.sh)"
done

out="$(./scripts/backtest-relation.sh "$MANIFEST")" && rc=0 || rc=$?
echo "$out"

[[ "$rc" -eq 0 ]] || fail "timeline did not match every expect"
echo "$out" | grep -q "rev2_overlong .*reject .*hex=C080" || fail "rev2 row must show reject with hex=C080"
echo "$out" | grep -q "rev1_honest .*accept" || fail "rev1 row must show accept"
echo "$out" | grep -q "rev3_fix .*accept" || fail "rev3 row must show accept"

echo "BACKTEST-UTF8 OK: timeline accept -> reject (C0 80) -> accept; NanoGraph flags exactly the buggy commit"
