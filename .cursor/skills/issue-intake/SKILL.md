---
name: issue-intake
description: Convert chat intent into a structured GitHub issue for NanoGraph work.
---

# Issue intake

Use when starting non-trivial work without an active issue.

## Steps

1. Summarize the request in one sentence.
2. Pick **Bound milestone: M*n*** from [`docs/specs/MILESTONES.md`](../../docs/specs/MILESTONES.md).
3. Create issue with title, problem, acceptance checklist, milestone line, verification section.
4. Label with one `milestone:m*` and one `type:*` per [`docs/specs/ISSUE-LABELS.md`](../../docs/specs/ISSUE-LABELS.md).
5. Patch `loop_state.json` with `current_issue`, `goal_id: "#<n>"`, `milestone`.
6. Return issue URL and number in chat.

## Command pattern

```bash
gh issue create --title "<title>" --label "milestone:m1,type:harness" --body "$(cat <<'EOF'
## Problem
...

## Acceptance
- [ ] ...

## Milestone
Bound milestone: M1

## Verification
- [ ] ./scripts/check-canonical-drift.sh
EOF
)"
```
