#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FLOW-COMPOSITION FAIL: $1" >&2; exit 1; }

echo "== flow_composition relation (G69) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "FLOW-COMPOSITION SKIP (no Linux runner)"
  exit 0
fi

REQ="fixtures/metamorphic/ca_flow90.req"
HONEST="fixtures/metamorphic/ca_flow90.ngb"
EVIL="fixtures/metamorphic/ca_flow90_evil.ngb"
RT_REQ="fixtures/metamorphic/utf8.req"
REL="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$REQ" "$HONEST" "$EVIL"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-ca-relation-fixtures.sh)"
done

out="$("$REL" "$HONEST" "$REQ" 2>/dev/null)" || fail "flow_composition rejected honest: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept: $out"
echo "$out"

out="$("$REL" "$EVIL" "$REQ" 2>/dev/null)" && fail "flow_composition accepted EVIL_SKIP"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for EVIL_SKIP: $out"
echo "$out"

echo "-- impact: round_trip schema does not apply to flow binary --"
if out_rt="$("$REL" "$EVIL" "$RT_REQ" 2>/dev/null)"; then
  fail "round_trip must not accept flow binary (wrong entry schema)"
fi

echo "FLOW-COMPOSITION OK: honest composes; EVIL_SKIP rejects with composition witness"
