#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "LINEAR-XOR FAIL: $1" >&2; exit 1; }

echo "== linear_xor relation (G67) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "LINEAR-XOR SKIP (no Linux runner)"
  exit 0
fi

REQ="fixtures/metamorphic/ca_step90.req"
HONEST="fixtures/metamorphic/ca_step90.ngb"
EVIL="fixtures/metamorphic/ca_step90_evil.ngb"
REL="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$REQ" "$HONEST" "$EVIL"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-ca-relation-fixtures.sh)"
done

out="$("$REL" "$HONEST" "$REQ" 2>/dev/null)" || fail "linear_xor rejected honest rule 90: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept for rule 90 step: $out"
echo "$out"

out="$("$REL" "$EVIL" "$REQ" 2>/dev/null)" && fail "linear_xor accepted rule 30 imposter"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for rule 30 imposter: $out"
echo "$out"

echo "LINEAR-XOR OK: rule 90 accepts; rule 30 imposter rejects with homomorphism witness"
