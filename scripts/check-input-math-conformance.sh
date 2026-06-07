#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "INPUT-MATH-CONFORMANCE FAIL: $1" >&2; exit 1; }

echo "== input-math conformance (G21) =="
if ! ./scripts/check-linux-runner.sh --quiet; then
  echo "INPUT-MATH-CONFORMANCE SKIP (no Linux runner: need Linux, qemu-x86_64, or docker)"
  exit 0
fi

make -C tools -s bin/conf-eval bin/ngb-extract bin/ngb-parse >/dev/null

SPEC="fixtures/input-math/gcd.spec"
CASES="fixtures/input-math/gcd.cases"
V1="fixtures/input-math/gcd_v1.ngb"
V2="fixtures/input-math/gcd_v2.ngb"
WRONG="fixtures/input-math/gcd_wrong.ngb"
LOG_DIR=".harness-data/agent-eval/conformance"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run.jsonl"

for f in "$SPEC" "$CASES" "$V1" "$V2" "$WRONG"; do
  [[ -f "$f" ]] || fail "missing $f (run scripts/mint-input-math-fixtures.sh)"
done

hash_of() { tools/bin/ngb-parse "$1" | sed -n 's/.*graph_root_hash=//p'; }

h1="$(hash_of "$V1")"
h2="$(hash_of "$V2")"
[[ "$h1" != "$h2" ]] || fail "gcd variants share graph_root_hash"

verdict() {
  local ngb="$1" a="$2" b="$3" expected="$4" observed ts
  observed="$(./scripts/run-linux-elf-capture.sh "$ngb" "$a" "$b" 2>/dev/null)" || true
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ "$observed" == "$expected" ]]; then
    printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"accept","a":%s,"b":%s}\n' \
      "$ts" "$SPEC" "$ngb" "$a" "$b" >>"$LOG"
    echo accept
  else
    printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","yield":"stdout","decision":"reject","a":%s,"b":%s}\n' \
      "$ts" "$SPEC" "$ngb" "$a" "$b" >>"$LOG"
    echo reject
  fi
}

wrong_rejected=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  read -r a b _expected <<<"$line"
  expected="$(tools/bin/conf-eval "$SPEC" "$a" "$b")"

  echo "-- gcd($a,$b): accept v1 (O0) --"
  [[ "$(verdict "$V1" "$a" "$b" "$expected")" == "accept" ]] || fail "v1 reject on ($a,$b)"

  echo "-- gcd($a,$b): accept v2 (O2) --"
  [[ "$(verdict "$V2" "$a" "$b" "$expected")" == "accept" ]] || fail "v2 reject on ($a,$b)"

  if [[ "$(verdict "$WRONG" "$a" "$b" "$expected")" == "reject" ]]; then
    wrong_rejected=1
  fi
done <"$CASES"

[[ "$wrong_rejected" -eq 1 ]] || fail "wrong specimen should reject on at least one case"

echo "gcd OK v1=${h1:0:12} v2=${h2:0:12}"
echo "INPUT-MATH-CONFORMANCE OK"
