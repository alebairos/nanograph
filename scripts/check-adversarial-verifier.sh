#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ADVERSARIAL-VERIFIER FAIL: $1" >&2; exit 1; }

echo "== adversarial verifier vs static sampling (G23) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "ADVERSARIAL-VERIFIER SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse >/dev/null

SPEC="fixtures/input-math/gcd.spec"
CASES="fixtures/input-math/gcd.cases"
EVIL="fixtures/input-math/gcd_evil.ngb"
V1="fixtures/input-math/gcd_v1.ngb"
V2="fixtures/input-math/gcd_v2.ngb"
VERIFY="./scripts/agent-eval/adversarial-verify.sh"

for f in "$SPEC" "$CASES" "$EVIL" "$V1" "$V2"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-input-math-fixtures.sh)"
done

echo "-- static arm: the fixed case suite accepts gcd_evil --"
matches=0
total=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  read -r a b _ <<<"$line"
  want="$(tools/bin/conf-eval "$SPEC" "$a" "$b")"
  got="$(./scripts/run-linux-elf-capture.sh "$EVIL" "$a" "$b" 2>/dev/null)" || got=""
  total=$((total + 1))
  [[ "$got" == "$want" ]] && matches=$((matches + 1))
done <"$CASES"
[[ "$matches" -eq "$total" ]] || fail "gcd_evil diverges on a static case; pick a bug the suite omits"
echo "static accepts gcd_evil on all $total cases (false negative)"

echo "-- adversarial arm: searcher rejects gcd_evil with a witness --"
out="$("$VERIFY" "$EVIL" "$SPEC" 2>/dev/null)" && fail "adversarial accepted gcd_evil"
echo "$out"
[[ "$out" == *"verdict=reject"* ]] || fail "expected reject for gcd_evil"
[[ "$out" == *"a=2 b=2"* ]] || fail "expected witness a=2 b=2 for gcd_evil, got: $out"

echo "-- adversarial arm: honest submissions accepted --"
for v in "$V1" "$V2"; do
  out="$("$VERIFY" "$v" "$SPEC" 2>/dev/null)" || fail "adversarial rejected honest $v: $out"
  [[ "$out" == *"verdict=accept"* ]] || fail "expected accept for $v, got: $out"
  echo "$out"
done

echo "ADVERSARIAL-VERIFIER OK: static misses what the searcher catches"
