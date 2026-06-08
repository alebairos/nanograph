#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "REVERSE32-REAL FAIL: $1" >&2; exit 1; }

echo "== both floors verify real vendored upstream code (G26) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "REVERSE32-REAL SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse >/dev/null

SRC="fixtures/metamorphic/reverse32.c"
SPEC="fixtures/metamorphic/reverse32.spec"
CASES="fixtures/metamorphic/reverse32.cases"
REQ="fixtures/metamorphic/reverse32.req"
HONEST="fixtures/metamorphic/reverse32.ngb"
EVIL="fixtures/metamorphic/reverse32_evil.ngb"
INVOLUTION_NOT_BITREV="fixtures/metamorphic/bswap32.ngb"
RELATION="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$SRC" "$SPEC" "$CASES" "$REQ" "$HONEST" "$EVIL" "$INVOLUTION_NOT_BITREV"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-metamorphic-fixtures.sh)"
done

echo "-- provenance: the function under test is vendored, not ours --"
grep -q "Bit Twiddling Hacks" "$SRC" || fail "no upstream attribution in $SRC"
grep -q "public domain" "$SRC" || fail "no license note in $SRC"
echo "attribution present (Bit Twiddling Hacks, public domain)"

echo "-- relation accepts the real bit reversal (involution, no oracle) --"
out="$("$RELATION" "$HONEST" "$REQ" 2>/dev/null)" || fail "relation rejected real reverse32: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept for real reverse32, got: $out"
echo "$out"

echo "-- relation rejects the mask-typo variant (non-involution) with a witness --"
out="$("$RELATION" "$EVIL" "$REQ" 2>/dev/null)" && fail "relation accepted the non-involution EVIL_REVERSE"
echo "$out"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for EVIL_REVERSE"

echo "-- oracle self-check: conf-eval op=bitrev matches the hand table --"
xs=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  read -r x expected <<<"$line"
  got="$(tools/bin/conf-eval "$SPEC" "$x")"
  [[ "$got" == "$expected" ]] || fail "conf-eval bitrev($x)=$got, hand table says $expected"
  xs+=("$x")
done <"$CASES"
echo "oracle self-check OK on ${#xs[@]} values"

echo "-- value oracle accepts the real bit reversal on every case --"
for x in "${xs[@]}"; do
  want="$(tools/bin/conf-eval "$SPEC" "$x")"
  got="$(./scripts/run-linux-elf-capture.sh "$HONEST" "$x" 2>/dev/null)" || got=""
  [[ "$got" == "$want" ]] || fail "real reverse32 rejected on x=$x (got=$got want=$want)"
done
echo "real reverse32 accepts all ${#xs[@]} cases"

echo "-- handoff: an involution that is not bit reversal (bswap32) --"
out="$("$RELATION" "$INVOLUTION_NOT_BITREV" "$REQ" 2>/dev/null)" || fail "relation rejected bswap32: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected relation accept for bswap32, got: $out"
echo "relation accepts bswap32 (it is an involution): $out"

witness=""
for x in "${xs[@]}"; do
  want="$(tools/bin/conf-eval "$SPEC" "$x")"
  got="$(./scripts/run-linux-elf-capture.sh "$INVOLUTION_NOT_BITREV" "$x" 2>/dev/null)" || got=""
  if [[ "$got" != "$want" ]]; then witness="x=$x got=$got want=$want"; break; fi
done
[[ -n "$witness" ]] || fail "value oracle did not separate bswap32 from bit reversal"
echo "value oracle rejects bswap32 as bit reversal; witness $witness"

echo "REVERSE32-REAL OK: real vendored code; relation accepts, non-involution rejected, value oracle separates a wrong involution ($witness)"
