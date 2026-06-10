#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "RELATION-TAXONOMY FAIL: $1" >&2; exit 1; }

echo "== relation taxonomy doc gate (G66) =="

[[ -f docs/specs/RELATION-TAXONOMY.md ]] || fail "missing docs/specs/RELATION-TAXONOMY.md"
[[ -f docs/adr/ADR-016-relation-taxonomy.md ]] || fail "missing ADR-016"

grep -q "Homomorphism" docs/specs/RELATION-TAXONOMY.md || fail "taxonomy missing Homomorphism family"
grep -q "Flow / composition" docs/specs/RELATION-TAXONOMY.md || fail "taxonomy missing Flow family"
grep -q "value_oracle.*point-oracle" docs/specs/RELATION-TAXONOMY.md || fail "taxonomy must label value_oracle"

grep -q "| Family |" docs/specs/METAMORPHIC-RELATIONS.md || fail "METAMORPHIC-RELATIONS missing family column"
grep -q "linear_xor" docs/specs/METAMORPHIC-RELATIONS.md || fail "METAMORPHIC-RELATIONS missing linear_xor"
grep -q "flow_composition" docs/specs/METAMORPHIC-RELATIONS.md || fail "METAMORPHIC-RELATIONS missing flow_composition"

grep -q "Family signal checklist" docs/BACKTEST.md || fail "BACKTEST missing family signal checklist"

echo "RELATION-TAXONOMY OK"
