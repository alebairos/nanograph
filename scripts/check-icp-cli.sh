#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-CLI FAIL: $1" >&2; exit 1; }

./scripts/nanograph doctor >/dev/null || fail "doctor failed"

tmp_fit="$(mktemp)"
cat >"$tmp_fit" <<'EOF'
name=cli_smoke
relation=round_trip
oracle_hardness=1
property_checkable=1
observable=1
silent_survival=1
criticality=1
EOF
./scripts/nanograph fit "$tmp_fit" >/dev/null || fail "fit failed"
rm -f "$tmp_fit"

./scripts/nanograph verify --expect accept \
  fixtures/metamorphic/utf8.ngb fixtures/metamorphic/utf8.req >/dev/null \
  || fail "verify accept failed"

./scripts/nanograph verify --expect reject \
  fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req >/dev/null \
  || fail "verify reject failed"

echo "ICP-CLI OK"
