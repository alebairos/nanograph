---
name: harness-quickstart
description: >-
  Onboard NanoGraph harness: session-start, loop_state, GitHub issue bind,
  loop driver.
---

# Harness quickstart

Normative: [`docs/specs/AGENT-HARNESS.md`](../../docs/specs/AGENT-HARNESS.md)

## First action

```bash
./scripts/harness-session-start.sh
```

Then **`nanograph-loop-driver`** unless waived.

## Dual bind (substantial work)

```text
Bound milestone: M1
Bound issue: #12
```

Create issue via `issue-intake` if missing. Patch `loop_state.json`:

```json
{
  "goal_id": "#12",
  "current_issue": 12,
  "milestone": "M0",
  "phase": "implementing"
}
```

## Loop

```text
session-start → issue-intake (if needed) → loop-driver → plan → implement → verify → issue-ship → issue-sync
```

## Checklist

```text
- [ ] harness-session-start
- [ ] milestone + issue bound
- [ ] loop-driver invoked
- [ ] spec_path before NGB-V0 / tools
- [ ] verification run
- [ ] gh issue comment on progress
- [ ] loop_state + memory updated
```
