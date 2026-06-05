# Task B (P14): two-agent print_42 → 43

Protocol: [`docs/specs/TWO-AGENT-PROBE-PROTOCOL.md`](../../docs/specs/TWO-AGENT-PROBE-PROTOCOL.md)

## Goal

Patch genesis `fixtures/print_42.ngb` so stdout is `43\n` and exit is 0.

## Author agent

**Inputs:** genesis `.ngb`, goal line, auditor `probe_bundle` from prior round.

**Tools:** `tools/bin/ngb-patch` (after P04).

**Forbidden reads:**

- `fixtures/print_42_patched*`
- `tools/bin/*-patch-fixture.c`
- Any file containing the golden delta bytes for this task

**Output per round:** `patch_request` then `patched.ngb` in eval workspace.

## Auditor agent

**Inputs:** genesis `.ngb`, author `patched.ngb`, goal line.

**Tools:** `ngb-parse --json`, `nano-probe disassemble`, `nano-probe diff`, `nano-probe audit-log`, `scripts/run-linux-elf-capture.sh`.

**Output per round:** `probe_bundle` then `verdict=accept` or `verdict=reject`.

## Success

- Auditor emits `verdict=accept`
- `run-linux-elf-capture.sh` on final patched graph prints `43\n`
- ≤5 author rounds
- Eval log written to `scripts/agent-eval/logs/p14-two-agent-<timestamp>.md`

## Metrics (for P16)

Record author rounds, wall clock, and whether author succeeded without reading forbidden paths.
