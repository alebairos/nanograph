#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-STALL-REPORT FAIL: $1" >&2; exit 1; }

[[ $# -ge 1 ]] || fail "usage: check-icp-stall-report.sh <STALL-REPORT.md>"

REPORT="$1"
[[ -f "$REPORT" ]] || fail "missing $REPORT"

step_re='^step=[0-9]+ surface=(README|ADOPTION|CLI|docs|own-code) action=.+ verdict=(ok|friction|stall)$'
result_re='^ICP-SIM RESULT completed=(yes|no) first_stall=(none|[0-9]+) friction=[0-9]+$'

steps=0
result_line=""
line_no=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ $step_re ]]; then
    steps=$((steps + 1))
    continue
  fi
  if [[ "$line" =~ $result_re ]]; then
    [[ -z "$result_line" ]] || fail "duplicate result line at $line_no"
    result_line="$line"
    continue
  fi
  if [[ "$line" =~ ^note= ]]; then
    continue
  fi
  fail "bad line $line_no: $line"
done <"$REPORT"

[[ "$steps" -ge 1 ]] || fail "no step records"
[[ -n "$result_line" ]] || fail "missing ICP-SIM RESULT line"

echo "ICP-STALL-REPORT OK steps=$steps $result_line"
