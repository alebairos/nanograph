#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CHECK-TWO-AGENT-LOOP FAIL: $1" >&2; exit 1; }

echo "== two-agent loop proof =="

chmod +x scripts/agent-eval/two-agent-auditor.sh
chmod +x scripts/agent-eval/run-two-agent-loop.sh

./scripts/agent-eval/run-two-agent-loop.sh

LOG=".harness-data/agent-eval/two-agent/run.jsonl"
[[ -f "$LOG" ]] || fail "missing log $LOG"

grep -q '"event":"loop_end"' "$LOG" || fail "missing loop_end"
grep -q '"decision":"reject"' "$LOG" || fail "missing auditor reject (lying/wrong author)"
grep -q '"decision":"accept"' "$LOG" || fail "missing auditor accept"
grep -q '"success":true' "$LOG" || fail "loop did not succeed"

rounds="$(grep '"event":"loop_end"' "$LOG" | sed -n 's/.*"rounds":\([0-9]*\).*/\1/p')"
[[ "$rounds" -le 5 ]] || fail "rounds $rounds > 5"

echo "CHECK-TWO-AGENT-LOOP OK rounds=$rounds"
