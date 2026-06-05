# Task A — add_two to exit 4

## Inputs

- `fixtures/add_two.ngb` (genesis only)

## Forbidden

- `fixtures/add_two_patched.ngb`, `fixtures/add_two_chain.ngb`
- `tools/bin/add-two-patch-fixture.c`, `tools/bin/add-two-chain-fixture.c`

## Goal

Linux ELF built from your patched `.ngb` exits with code **4** (`2+2`).

## Success

1. `ngb-parse --json` returns `ok:true`
2. `./scripts/run-linux-elf.sh <your.ngb>` exits 4
3. `nano-probe audit-log` shows two patches with chained preconditions genesis → exit3 → exit4

## Hints allowed

- `ngb-patch --json` invariant strings on failure
- `nano-probe disassemble` for code offsets (not golden files)
