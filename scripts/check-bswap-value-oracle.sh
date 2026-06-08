#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "BSWAP-VALUE-ORACLE FAIL: $1" >&2; exit 1; }

echo "== bswap value oracle closes the involution ceiling (G25) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "BSWAP-VALUE-ORACLE SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse >/dev/null

SPEC="fixtures/metamorphic/bswap32.spec"
CASES="fixtures/metamorphic/bswap32.cases"
REQ="fixtures/metamorphic/bswap32.req"
HONEST="fixtures/metamorphic/bswap32.ngb"
IMPOSTER="fixtures/metamorphic/bswap32_imposter.ngb"
RELATION="./scripts/agent-eval/metamorphic-verify.sh"

for f in "$SPEC" "$CASES" "$REQ" "$HONEST" "$IMPOSTER"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-metamorphic-fixtures.sh)"
done

xs=()
echo "-- oracle self-check: conf-eval op=bswap matches the hand table --"
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  read -r x expected <<<"$line"
  got="$(tools/bin/conf-eval "$SPEC" "$x")"
  [[ "$got" == "$expected" ]] || fail "conf-eval bswap($x)=$got, hand table says $expected"
  xs+=("$x")
done <"$CASES"
echo "oracle self-check OK on ${#xs[@]} values"

echo "-- value oracle accepts honest bswap32 on every case --"
for x in "${xs[@]}"; do
  want="$(tools/bin/conf-eval "$SPEC" "$x")"
  got="$(./scripts/run-linux-elf-capture.sh "$HONEST" "$x" 2>/dev/null)" || got=""
  [[ "$got" == "$want" ]] || fail "honest rejected on x=$x (got=$got want=$want)"
done
echo "honest accepts all ${#xs[@]} cases"

echo "-- value oracle rejects the imposter with a value witness --"
rejects=0
witness=""
for x in "${xs[@]}"; do
  want="$(tools/bin/conf-eval "$SPEC" "$x")"
  got="$(./scripts/run-linux-elf-capture.sh "$IMPOSTER" "$x" 2>/dev/null)" || got=""
  if [[ "$got" != "$want" ]]; then
    rejects=$((rejects + 1))
    [[ -z "$witness" ]] && witness="x=$x got=$got want=$want"
  fi
done
[[ "$rejects" -ge 1 ]] || fail "value oracle accepted the imposter on every case"
echo "value oracle rejects imposter on $rejects/${#xs[@]} cases; witness $witness"

echo "-- handoff: the involution relation accepts the same imposter --"
out="$("$RELATION" "$IMPOSTER" "$REQ" 2>/dev/null)" || fail "relation rejected the imposter; G24 ceiling no longer holds: $out"
[[ "$out" == *"verdict=accept"* ]] || fail "expected relation accept for imposter, got: $out"
echo "$out"

echo "BSWAP-VALUE-ORACLE OK: relation accepts, value oracle rejects ($witness); cheap-then-expensive floors compose"
