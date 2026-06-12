#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-SIM-EVAL FAIL: $1" >&2; exit 1; }

usage() {
  echo "usage: check-icp-sim-eval.sh <STALL-REPORT.md> [baseline.json]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
REPORT="$1"
BASELINE="${2:-fixtures/icp-sim/baseline.json}"

[[ -f "$REPORT" ]] || fail "missing $REPORT"
[[ -f "$BASELINE" ]] || fail "missing $BASELINE"

./scripts/check-icp-stall-report.sh "$REPORT" >/dev/null

RESULT_LINE="$(grep -E '^ICP-SIM RESULT completed=(yes|no) first_stall=(none|[0-9]+) friction=[0-9]+$' "$REPORT" | tail -1)"
[[ -n "$RESULT_LINE" ]] || fail "missing result line"

completed="$(sed -n 's/^ICP-SIM RESULT completed=\([^ ]*\).*/\1/p' <<<"$RESULT_LINE")"
first_stall="$(sed -n 's/^ICP-SIM RESULT completed=[^ ]* first_stall=\([^ ]*\).*/\1/p' <<<"$RESULT_LINE")"
friction="$(sed -n 's/^ICP-SIM RESULT .* friction=\([0-9]*\)$/\1/p' <<<"$RESULT_LINE")"

read_json_field() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$key // empty" "$BASELINE"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$BASELINE" "$key" <<'PY'
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
cur = data
for part in key.strip(".").split("."):
    if part == "":
        continue
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        sys.exit(0)
if cur is None:
    sys.exit(0)
print(cur)
PY
  else
    fail "need jq or python3 to read baseline.json"
  fi
}

expect_completed="$(read_json_field ".expect.completed")"
expect_first_stall="$(read_json_field ".expect.first_stall")"
expect_not_before="$(read_json_field ".expect.first_stall_not_before")"
friction_max="$(read_json_field ".expect.friction_max")"

if [[ -n "$expect_completed" && "$expect_completed" != "null" ]]; then
  [[ "$completed" == "$expect_completed" ]] || fail "completed=$completed want $expect_completed"
fi

if [[ -n "$expect_first_stall" && "$expect_first_stall" != "null" ]]; then
  [[ "$first_stall" == "$expect_first_stall" ]] || fail "first_stall=$first_stall want $expect_first_stall"
fi

if [[ -n "$expect_not_before" && "$expect_not_before" != "null" ]]; then
  if [[ "$first_stall" != "none" ]]; then
    [[ "$first_stall" -ge "$expect_not_before" ]] \
      || fail "first_stall=$first_stall regressed before step $expect_not_before (mechanical adoption)"
  fi
fi

if [[ -n "$friction_max" && "$friction_max" != "null" ]]; then
  [[ "$friction" -le "$friction_max" ]] || fail "friction=$friction exceeds max $friction_max"
fi

echo "ICP-SIM-EVAL OK $RESULT_LINE baseline=$BASELINE"
