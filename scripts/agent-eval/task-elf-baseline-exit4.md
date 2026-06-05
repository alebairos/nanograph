# ELF baseline — add_two exit 4

## Inputs

- `fixtures/add_two_elf.bin` only (no `.ngb`, no `ngb-patch`)

## Goal

Edit raw ELF bytes so Linux run exits **4**.

## Success

1. Patched ELF runs under qemu-x86_64 or Docker linux with exit 4
2. Document hex offsets changed and old/new bytes in eval log

## Compare

Same goal as Task A. Metrics in `docs/specs/AGENT-EVAL-METRICS.md` compare iteration count and wall time.
