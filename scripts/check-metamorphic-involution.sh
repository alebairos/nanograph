#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "METAMORPHIC-INVOLUTION FAIL: $1" >&2; exit 1; }

echo "== metamorphic involution (G24) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "METAMORPHIC-INVOLUTION SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

REQ="fixtures/metamorphic/bswap32.req"
HONEST="fixtures/metamorphic/bswap32.ngb"
EVIL="fixtures/metamorphic/bswap32_evil.ngb"
IMPOSTER="fixtures/metamorphic/bswap32_imposter.ngb"
VERIFY="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$REQ" "$HONEST" "$EVIL" "$IMPOSTER"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-metamorphic-fixtures.sh)"
done

echo "-- honest bswap32 accepts (involution holds, no oracle) --"
out="$("$VERIFY" "$HONEST" "$REQ" 2>/dev/null)" || fail "honest bswap32 rejected: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept for honest, got: $out"
echo "$out"

echo "-- rotl8 (non-involution) rejected with a witness --"
out="$("$VERIFY" "$EVIL" "$REQ" 2>/dev/null)" && fail "involution accepted the rotl8 imposter"
echo "$out"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for rotl8"
[[ "$out" == *"x=1"* ]] || fail "expected witness x=1 for rotl8, got: $out"

echo "-- ceiling: an involution-but-wrong bswap accepts --"
out="$("$VERIFY" "$IMPOSTER" "$REQ" 2>/dev/null)" || fail "imposter rejected (should accept; it is an involution): $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept for imposter, got: $out"
echo "$out"
echo "ceiling documented: involution is necessary, not sufficient; a value oracle is needed to reject the imposter"

echo "METAMORPHIC-INVOLUTION OK: relation is its own oracle; non-involution rejected, ceiling explicit"
