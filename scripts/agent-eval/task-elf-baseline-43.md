# ELF baseline — print_42 to 43

## Inputs

- `fixtures/print_42_elf.bin` only

## Goal

Stdout is `43\n` with exit 0 after hex editing the ELF rodata or code path.

## Success

1. Capture stdout via `./scripts/run-linux-elf-capture.sh` on your ELF
2. Log offsets and byte pairs in eval artifact

## Compare

Same goal as Task B (two-agent). Metrics table records ngb vs ELF effort.
