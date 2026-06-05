#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "AGENT-EVAL FAIL: $1" >&2; exit 1; }

TASK=""
DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    task-a|task-b|elf-a|elf-b) TASK="$1"; shift ;;
    *) fail "unknown arg $1" ;;
  esac
done

[[ -n "$TASK" ]] || fail "usage: run-task.sh [--dry-run] task-a|task-b|elf-a|elf-b"

case "$TASK" in
  task-a) TASK_FILE="scripts/agent-eval/task-add-two-exit4.md" ;;
  task-b) TASK_FILE="scripts/agent-eval/task-print-42-43-two-agent.md" ;;
  elf-a) TASK_FILE="scripts/agent-eval/task-elf-baseline-exit4.md" ;;
  elf-b) TASK_FILE="scripts/agent-eval/task-elf-baseline-43.md" ;;
esac

[[ -f "$TASK_FILE" ]] || fail "missing $TASK_FILE"

OUT_DIR=".harness-data/agent-eval/$TASK"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/run.jsonl"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{"ts":"%s","task":"%s","mode":"%s","success":null,"iterations":0,"note":"skeleton"}\n' \
  "$TS" "$TASK" "$( [[ "$DRY" -eq 1 ]] && echo dry-run || echo live )" >>"$LOG"

if [[ "$DRY" -eq 1 ]]; then
  echo "AGENT-EVAL OK dry-run task=$TASK log=$LOG"
  exit 0
fi

echo "AGENT-EVAL OK task=$TASK log=$LOG (live stub; run agent manually)"
exit 0
