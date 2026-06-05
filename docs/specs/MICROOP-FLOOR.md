# Micro-op floor (G10)

Static integrity gate for agent-authored edits. A typed micro-operation carries a structural claim checked before any byte delta is applied or any ELF is run.

Issue #32. Stacks under G9 execution-grounded conformance.

## Data shape

`MicroOpRodataByteWrite` from a key=value spec file:

| Field | Required | Meaning |
| --- | --- | --- |
| `kind` | yes | `rodata_byte_write` (v0 only op) |
| `image_off` | yes | byte offset inside the ELF image slice |
| `new` | yes | new byte value (hex) |
| `expect_old` | no | genesis byte at `image_off` must match (hex) |

Static verdict: `static=accept` or `static=reject invariant=<reason>`.

## Static claim (RODATA_BYTE_WRITE)

Exactly one byte changes. The offset must classify as rodata under the same linear disassembly walk `nano-probe disassemble` uses. Instruction immediates and opcodes reject with `not_rodata`.

This is integrity over the delta, not intention. Wrong rodata values still pass static and fail at execution (G8/G9).

## Components

| Path | Role |
| --- | --- |
| `tools/ngb/microop.c` | Parse, validate, materialize to `NgbPatchInput` |
| `tools/bin/ngb-microop` | CLI apply or `--check-only` |
| `fixtures/microop/*.microop` | Declared ops |
| `scripts/check-microop-floor.sh` | CI gate |

## Demonstration (print_42)

| Spec | Static | Behavioral |
| --- | --- | --- |
| `print_42_rodata_43.microop` (off 152, 32→33) | accept | stdout `43\n`, hash matches `print_42_patched` |
| `print_42_code_imm.microop` (off 135, mov edx) | reject `not_rodata` | not run |

## Relation to raw `ngb-patch`

Raw pairs expose offset encoding to the agent. Micro-ops name the intent class; the tool derives the pair. Agents emit `kind=rodata_byte_write` instead of `--off 152 --pair 32:33`.
