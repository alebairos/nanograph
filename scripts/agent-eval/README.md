# Agent eval harness

Reproducible tasks for product proof P12–P16. Logs land under `.harness-data/agent-eval/<task-id>/`.

## Rubric

| Field | Meaning |
| --- | --- |
| `success` | Task success criteria met |
| `iterations` | Tool rounds until success or stop |
| `wall_ms` | Elapsed time |
| `tool_calls` | Count of patch/parse/probe invocations |

## Constraints (Task A/B)

- May use `ngb-patch`, `ngb-parse --json`, `nano-probe diff`, `nano-probe audit-log`, `nano-probe trace`
- May NOT read golden patched fixtures or patch fixture C sources
- Must start from genesis `.ngb` only

## Tasks

| ID | File | Goal |
| --- | --- | --- |
| task-a | `task-add-two-exit4.md` | add_two genesis → exit 4 |
| task-b | `task-print-42-43-two-agent.md` | print_42 → stdout `43\n` (two-agent) |
| elf-a | `task-elf-baseline-exit4.md` | Raw ELF hex edit → exit 4 |
| elf-b | `task-elf-baseline-43.md` | Raw ELF hex edit → stdout `43\n` |

## Two-agent loop (G8)

| Script | Purpose |
| --- | --- |
| `two-agent-auditor.sh` | Emit `probe_bundle` + `verdict` from genesis + patched `.ngb` |
| `run-two-agent-loop.sh` | Deterministic author/auditor rounds with JSONL log |
| `check-two-agent-loop.sh` | CI gate (wrong patch rejected, correct patch accepted ≤5 rounds) |

Log: `.harness-data/agent-eval/two-agent/run.jsonl`

## Run

```bash
./scripts/agent-eval/run-task.sh --dry-run task-a
./scripts/agent-eval/run-eval-sprint.sh
./scripts/check-two-agent-loop.sh
```

`run-eval-sprint.sh` executes measured Task A + ELF baseline (issue #29) and appends JSONL logs. Dry-run checks task file presence only.
