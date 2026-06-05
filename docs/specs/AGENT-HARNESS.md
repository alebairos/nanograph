# Agent harness (NanoGraph specialist)

Lightweight harness modeled on **boxless-web-poc** lite delivery and **durable-chat** gates (system design, issues, planning). No `agency.sh` or BrainDB.

## Core pieces

| Layer | Path | Purpose |
| --- | --- | --- |
| Entry | [`AGENTS.md`](../../AGENTS.md) | Read order and Cursor map |
| System design | `.cursor/rules/01-system-design.mdc` | Non-negotiable layering (always on) |
| Quality gates | `.cursor/rules/02-quality-gates.mdc` | Verify before done |
| Goal loop | `.cursor/rules/03-goal-loop.mdc` | Bounded iteration |
| Milestone delivery | `.cursor/rules/04-milestone-driven-delivery.mdc` | Bind **M*n*** + **#issue** |
| Planning / design | `.cursor/rules/05-planning-gate.mdc`, `06-design-declaration.mdc` | Checklist + boundary block |
| Loop harness | `.cursor/rules/07-harness-loop.mdc` | `loop_state.json` + loop driver |
| Issue execution | `.cursor/rules/08`–`10` | Issue-first, PR linkage, sync |
| Issue skills | `.cursor/skills/issue-intake`, `issue-ship` | Create and close work units |
| Label taxonomy | [`ISSUE-LABELS.md`](ISSUE-LABELS.md) | `milestone:m*`, `type:*`, `area:*` |
| Milestone gate | `.cursor/skills/milestone-gate/SKILL.md` | Per-milestone verify |
| Boundary gate | `.cursor/skills/ngb-boundary-gate/SKILL.md` | I1–I6 |
| Quickstart | `.cursor/skills/harness-quickstart/SKILL.md` | Session start, state patch |
| Loop driver | `.cursor/agents/nanograph-loop-driver.md` | Orchestrate one issue slice |
| Canonical map | [`docs/CANONICAL.md`](../CANONICAL.md) | Anti-drift pointers |
| Loop state | `.harness-data/loop_state.json` | `current_issue`, milestone, phase |
| Labels script | `scripts/setup-github-labels.sh` | One-time repo label setup |
| Session | `scripts/harness-session-start.sh` | State + optional `gh issue view` |

## Omitted from durable-chat (on purpose)

| DC mechanism | Why omitted |
| --- | --- |
| `agency.sh` / BrainDB | Contract memory in git is enough |
| Ready queue / adversarial loop | Specialist repo; query issues by label |
| Eval bundles | Use milestone-gate scripts |

## Default execution loop

1. `./scripts/harness-session-start.sh`
2. **Bound milestone: M*n*** and **Bound issue: #n** (create via `issue-intake` if missing)
3. `nanograph-loop-driver` unless user waives
4. Canonical first for format/philosophy changes
5. Design declaration + planning checklist
6. Smallest change matching issue acceptance
7. Verify per `milestone-gate`
8. `issue-ship` on PR; `10-issue-sync` on progress
9. Patch `loop_state.json` and `memory/items.yaml`
10. Regenerate [`STORY-SO-FAR.md`](../STORY-SO-FAR.md) with `./scripts/update-story.sh` when closing an issue

## When to escalate

- `.ngb` v0 version bump
- Patch-chain or signature policy change
- `probe verify` before M4
- v2 JSON audit manifest inside `.ngb`

## External style

pstack `/poteto-mode` on non-trivial work.
