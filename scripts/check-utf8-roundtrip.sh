#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "UTF8-ROUNDTRIP FAIL: $1" >&2; exit 1; }

echo "== round_trip catches an overlong decoder a unit test misses (G27) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "UTF8-ROUNDTRIP SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

REQ="fixtures/metamorphic/utf8.req"
HONEST="fixtures/metamorphic/utf8.ngb"
BUGGY="fixtures/metamorphic/utf8_overlong.ngb"
RELATION="./scripts/agent-eval/metamorphic-verify.sh"
BATCH="./scripts/run-linux-elf-batch.sh"

for f in "$REQ" "$HONEST" "$BUGGY"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-metamorphic-fixtures.sh)"
done

batch_mode() {
  local ngb="$1" mode="$2"
  while read -r v; do [[ -z "$v" ]] && continue; printf '%s %s\n' "$mode" "$v"; done \
    | "$BATCH" "$ngb" 2>/dev/null | awk '{print $3}'
}

unit_test() {
  local ngb="$1"
  shift
  local cps=("$@") packed=() decoded=()
  while read -r p; do packed+=("$p"); done < <(printf '%s\n' "${cps[@]}" | batch_mode "$ngb" enc)
  while read -r d; do decoded+=("$d"); done < <(printf '%s\n' "${packed[@]}" | batch_mode "$ngb" dec)
  for i in "${!cps[@]}"; do
    [[ "${decoded[$i]:-}" == "${cps[$i]}" ]] || return 1
  done
  return 0
}

echo "-- the fixed canonical unit test passes on BOTH binaries --"
canon=(0 65 233 8364 128512)
for ngb in "$HONEST" "$BUGGY"; do
  ok=1
  for attempt in 1 2 3; do
    if unit_test "$ngb" "${canon[@]}"; then ok=0; break; fi
  done
  [[ "$ok" -eq 0 ]] || fail "canonical round-trip broke on $ngb (decode(encode(cp))!=cp)"
done
echo "decode(encode(cp))==cp holds for ${#canon[@]} canonical codepoints on honest AND overlong-buggy"

echo "-- relation accepts the honest codec --"
out="$("$RELATION" "$HONEST" "$REQ" 2>/dev/null)" || fail "relation rejected the honest codec: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected accept for honest codec, got: $out"
echo "$out"

echo "-- relation rejects the overlong-accepting codec with the offending bytes --"
out="$("$RELATION" "$BUGGY" "$REQ" 2>/dev/null)" && fail "relation accepted the overlong codec"
echo "$out"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for overlong codec"
[[ "$out" == *"hex=C080"* ]] || fail "expected witness bytes C0 80 (overlong NUL), got: $out"
[[ "$out" == *"decode=0"* ]] || fail "expected the overlong NUL to decode to U+0000, got: $out"

echo "UTF8-ROUNDTRIP OK: unit test green on the buggy decoder; round_trip rejects it with witness C0 80 -> U+0000"
