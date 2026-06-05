#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== NanoGraph harness session =="
echo "repo: $ROOT"
echo ""

for f in AGENTS.md docs/CANONICAL.md docs/specs/AGENT-HARNESS.md docs/specs/ISSUE-LABELS.md .harness-data/loop_state.json; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f" >&2
    exit 1
  fi
done

echo "-- loop_state --"
if command -v jq >/dev/null 2>&1; then
  jq '{goal_id, current_issue, milestone, product_proof_step, phase, iteration, artifacts, next_action}' .harness-data/loop_state.json
else
  cat .harness-data/loop_state.json
fi
echo ""

if [[ -f .harness-data/product_proof_queue.json ]] && command -v jq >/dev/null 2>&1; then
  echo "-- product_proof_queue --"
  jq '{program, current_step, current_issue, phase, total_steps}' .harness-data/product_proof_queue.json
  echo ""
fi

ISSUE_NUM=""
if command -v jq >/dev/null 2>&1; then
  ISSUE_NUM="$(jq -r '.current_issue // empty' .harness-data/loop_state.json)"
fi

if [[ -n "$ISSUE_NUM" && "$ISSUE_NUM" != "null" ]] && command -v gh >/dev/null 2>&1; then
  echo "-- bound issue --"
  if gh issue view "$ISSUE_NUM" --json number,title,state,labels 2>/dev/null; then
    :
  else
    echo "WARN: could not load issue #$ISSUE_NUM (repo remote or auth?)" >&2
  fi
  echo ""
fi

echo "-- memory summary --"
head -n 24 .harness-data/memory/summary.md
echo ""

./scripts/check-canonical-drift.sh

echo ""
echo "Next: bind milestone + issue; invoke nanograph-loop-driver unless waived."
