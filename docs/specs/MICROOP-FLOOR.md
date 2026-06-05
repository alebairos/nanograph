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

This is integrity over the delta. Wrong rodata target classes reject structurally.

## Value binding (G12)

`--expect-new HH` adds a value claim on top of the structural one. After rodata validation, the written byte must equal `HH` or the gate emits `static=reject invariant=value_mismatch`. The expected byte is derived independently, not asserted. The gate runs `conf-eval` on `fixtures/conformance/print_43_stdout.spec` (`add(21,22)` renders `43\n`), takes the digit at `image_off - string_off`, and passes it as `--expect-new`. The wrong-digit author (`new=34`) rejects before any execution, the round-2-to-round-1 reduction at the static layer. The correct author (`new=33`) passes.

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
| `print_42_rodata_43.microop` + `--expect-new 33` | accept (value-bound) | not run |
| `print_42_rodata_44.microop` + `--expect-new 33` | reject `value_mismatch` | not run |

## Relation to raw `ngb-patch`

Raw pairs expose offset encoding to the agent. Micro-ops name the intent class; the tool derives the pair. Agents emit `kind=rodata_byte_write` instead of `--off 152 --pair 32:33`.
