# NanoGraph (NanoLang v3 sketch)

Specialist repo for the **agent-first binary graph** (`.ngb`) and post-hoc **NanoProbe** tooling.

## Read first

1. [`nanograph.md`](nanograph.md) — concept thread (v3 stance)
2. [`docs/CANONICAL.md`](docs/CANONICAL.md) — doc ownership
3. [`docs/specs/AGENT-HARNESS.md`](docs/specs/AGENT-HARNESS.md) — execution loop
4. [`docs/specs/MILESTONES.md`](docs/specs/MILESTONES.md) — **M0–M4**
5. [`docs/specs/ISSUE-LABELS.md`](docs/specs/ISSUE-LABELS.md) — GitHub labels

## Cursor harness

| Mechanism | Path |
| --- | --- |
| System design | `.cursor/rules/01-system-design.mdc` |
| Quality / goal / milestone | `.cursor/rules/02`–`04` |
| Planning / design / loop | `.cursor/rules/05`–`07` |
| Issues | `.cursor/rules/08`–`10` |
| Session + issues | `.cursor/skills/harness-quickstart`, `issue-intake`, `issue-ship` |
| Loop driver | `.cursor/agents/nanograph-loop-driver.md` |

## Session start

```bash
./scripts/harness-session-start.sh
```

Bind **Bound milestone: M*n*** and **Bound issue: #n** before substantial edits.

## GitHub setup (once per clone)

```bash
./scripts/setup-github-labels.sh
```

## External style

pstack `/poteto-mode` for non-trivial work.
