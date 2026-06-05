## Problem

NanoGraph harness used milestones only. Work was not persisted in GitHub Issues like durable-chat. We need issue-first execution, PR linkage, and sync wired into loop_state and agents.

## Milestone

Bound milestone: M0

## Internal checklist (10 steps)

- [x] 1. Add `docs/specs/ISSUE-LABELS.md` (`milestone:m*`, `type:*`, `area:*`)
- [x] 2. Add `.cursor/rules/08-issue-first-execution.mdc`
- [x] 3. Add `.cursor/rules/09-issue-pr-linkage.mdc`
- [x] 4. Add `.cursor/rules/10-issue-sync.mdc`
- [x] 5. Add `.cursor/skills/issue-intake` and `issue-ship`
- [x] 6. Update `04-milestone-driven-delivery.mdc` (dual bind milestone + issue)
- [x] 7. Extend `loop_state.json` with `current_issue`
- [x] 8. Update `nanograph-loop-driver` and `harness-quickstart` (+ session-start `gh issue view`)
- [x] 9. Update `AGENT-HARNESS.md` (issues required, not optional)
- [x] 10. Initialize git repo and push to GitHub via `gh`

## Verification

- [x] `./scripts/harness-session-start.sh` shows bound issue
- [x] `./scripts/check-canonical-drift.sh` passes
- [x] `./scripts/setup-github-labels.sh` idempotent
- [x] `loop_state.json` has `current_issue` matching this issue

## Acceptance

- [x] All 10 internal checklist items complete
- [x] Labels exist on repo
- [x] Dogfood comment posted with verification summary
