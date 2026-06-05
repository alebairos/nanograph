#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "DRIFT: $1" >&2; exit 1; }

# Forbidden duplicate concept trees
if [[ -f docs/nanograph-concept.md ]] || [[ -f docs/nanograph.md ]]; then
  fail "duplicate concept doc under docs/; use root nanograph.md only"
fi

if [[ -d docs/adr ]] && [[ $(find docs/adr -name '*.md' 2>/dev/null | wc -l) -gt 0 ]]; then
  : # ADRs allowed when added intentionally
fi

# v2-style audit manifest must not appear as canonical
if grep -rq '\.naudit' docs/specs/NGB-V0.md 2>/dev/null; then
  fail "NGB-V0 must not canonicalize .naudit sidecars"
fi

for required in nanograph.md docs/CANONICAL.md docs/specs/NGB-V0.md docs/specs/MILESTONES.md; do
  [[ -f "$required" ]] || fail "missing canonical file: $required"
done

echo "OK: canonical drift check passed"
