#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "INPUT-MATH-ORACLE FAIL: $1" >&2; exit 1; }

echo "== input-math oracle (G21) =="
make -C tools -s bin/conf-eval >/dev/null

SPEC="fixtures/input-math/gcd.spec"
CASES="fixtures/input-math/gcd.cases"
[[ -f "$SPEC" ]] || fail "missing $SPEC"
[[ -f "$CASES" ]] || fail "missing $CASES"

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  read -r a b expected <<<"$line"
  got="$(tools/bin/conf-eval "$SPEC" "$a" "$b")"
  want="$(printf '%s\n' "$expected")"
  [[ "$got" == "$want" ]] || fail "gcd($a,$b) got=$(printf '%q' "$got") want=$expected"
  echo "gcd($a,$b)=$expected OK"
done <"$CASES"

echo "INPUT-MATH-ORACLE OK"
