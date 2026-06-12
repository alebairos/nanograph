#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-ADOPTION-SANDBOX FAIL: $1" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

./scripts/agent-eval/prepare-icp-sim-sandbox.sh "$WORK/sandbox" >/dev/null
SANDBOX="$WORK/sandbox"
cd "$SANDBOX"

./nanograph doctor 2>&1 | grep -q 'runner=' || fail "doctor missing runner="

./nanograph demo utf8 >/dev/null || fail "demo utf8 failed"

tmp_fit="$(mktemp)"
cat >"$tmp_fit" <<'EOF'
name=icp_sandbox_smoke
relation=round_trip
oracle_hardness=1
property_checkable=1
observable=1
silent_survival=1
criticality=1
EOF
./nanograph fit "$tmp_fit" >/dev/null || fail "fit failed"
rm -f "$tmp_fit"

./nanograph verify --expect accept \
  fixtures/metamorphic/utf8.ngb fixtures/metamorphic/utf8.req >/dev/null \
  || fail "verify accept failed"

reject_out="$(mktemp)"
if ! ./nanograph verify --expect reject \
  fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req \
  >"$reject_out" 2>&1; then
  fail "verify reject failed ($(cat "$reject_out"))"
fi
grep -q 'verdict=reject' "$reject_out" || fail "reject missing verdict=reject ($(cat "$reject_out"))"
grep -q 'witness' "$reject_out" || fail "reject missing witness ($(cat "$reject_out"))"
rm -f "$reject_out"

cd "$ROOT"

tmp_bswap="$(mktemp)"
./nanograph mint c fixtures/metamorphic/bswap32.c "$tmp_bswap" >/dev/null \
  || fail "mint bswap32 failed"
./nanograph verify --expect accept "$tmp_bswap" fixtures/metamorphic/bswap32.req >/dev/null \
  || fail "verify bswap32 accept failed"
rm -f "$tmp_bswap"

tmp_hex="$(mktemp)"
./nanograph mint c fixtures/templates/icp-hex-specimen.c "$tmp_hex" >/dev/null \
  || fail "mint icp-hex template failed"
./nanograph verify --expect accept "$tmp_hex" fixtures/templates/icp-hex-roundtrip.req >/dev/null \
  || fail "verify icp-hex round_trip failed"
rm -f "$tmp_hex"

echo "ICP-ADOPTION-SANDBOX OK"
