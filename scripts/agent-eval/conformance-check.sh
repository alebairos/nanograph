#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

usage() {
  echo "usage: conformance-check.sh <spec> <ngb>" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage
SPEC="$1"
NGb="$2"
[[ -f "$SPEC" ]] || { echo "conformance-check: missing spec $SPEC" >&2; exit 2; }
[[ -f "$NGb" ]] || { echo "conformance-check: missing ngb $NGb" >&2; exit 2; }

make -C tools -s bin/conf-eval bin/ngb-extract >/dev/null

expected="$(tools/bin/conf-eval "$SPEC")"

set +e
./scripts/run-linux-elf-capture.sh "$NGb" >/dev/null 2>&1
observed=$?
set -e

LOG_DIR=".harness-data/agent-eval/conformance"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run.jsonl"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$observed" -eq "$expected" ]]; then
  printf 'verdict=accept expected=%s observed=%s\n' "$expected" "$observed"
  printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","expected":%s,"observed":%s,"decision":"accept"}\n' \
    "$ts" "$SPEC" "$NGb" "$expected" "$observed" >>"$LOG"
  exit 0
fi

printf 'verdict=reject expected=%s observed=%s detail=bytes do not realize spec\n' "$expected" "$observed"
printf '{"ts":"%s","msg_type":"verdict","spec":"%s","ngb":"%s","expected":%s,"observed":%s,"decision":"reject"}\n' \
  "$ts" "$SPEC" "$NGb" "$expected" "$observed" >>"$LOG"
exit 1
