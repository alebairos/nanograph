#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "RULE184-CONSERVE FAIL: $1" >&2; exit 1; }

echo "== rule 184 conserve_popcount bridge (G68) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "RULE184-CONSERVE SKIP (no Linux runner)"
  exit 0
fi

REQ="fixtures/metamorphic/ca_step184.req"
HONEST="fixtures/metamorphic/ca_step184.ngb"
EVIL="fixtures/metamorphic/ca_step184_evil.ngb"
INV_REQ="fixtures/metamorphic/bswap32.req"
REL="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$REQ" "$HONEST" "$EVIL"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-ca-relation-fixtures.sh)"
done

out="$("$REL" "$HONEST" "$REQ" 2>/dev/null)" || fail "conserve_popcount rejected honest rule 184: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept: $out"
echo "$out"

out="$("$REL" "$EVIL" "$REQ" 2>/dev/null)" && fail "conserve_popcount accepted EVIL_DROP"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for EVIL_DROP: $out"
echo "$out"

echo "-- impact: involution does not apply to ca_step (not involution-shaped) --"
if out_inv="$("$REL" "$EVIL" "$INV_REQ" 2>/dev/null)"; then
  [[ "$out_inv" == *"verdict=accept"* ]] && fail "involution must not accept EVIL_DROP on step mode (wrong relation schema)"
fi

echo "RULE184-CONSERVE OK: particle-conserving rule 184 step accepts; EVIL_DROP rejects"
