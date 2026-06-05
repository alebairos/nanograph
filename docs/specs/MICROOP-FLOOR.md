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

`--expect-off N` and `--expect-new HH` add positional and value claims on top of the structural one. After rodata validation, `image_off` must equal `N` (`position_mismatch`) and the written byte must equal `HH` (`value_mismatch`). Both are derived independently from `conf-eval` on `fixtures/conformance/print_43_stdout.spec` (`add(21,22)` renders `43\n`). The harness computes `expect_off = string_off + digit_index` and `expect_new` from the rendered digit. Wrong digit (`new=34`), wrong position (`off=151`), and wrong target class all reject before execution.

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
| `print_42_rodata_43_wrongpos.microop` + `--expect-off 152 --expect-new 33` | reject `position_mismatch` | not run |

## Operational-error coverage (the proper test)

What the gate actually buys is measured deterministically by `scripts/agent-eval/operational-error-matrix.sh`. It enumerates every operational error class for a `rodata_byte_write` on `print_42` and records where each is caught, with the static gate versus auditor-only (no gate). No live model, so no variance.

| Error class | Bytes | Static gate | Auditor-only (no gate) | Execution saved |
| --- | --- | --- | --- | --- |
| correct | off 152, 32→33 | accept | accept | n/a (control) |
| wrong value | off 152, 32→34 | reject `value_mismatch` (0 exec) | reject `stdout` (1 exec) | yes |
| wrong target, instruction byte | off 135, ba→33 | reject `not_rodata` (0 exec) | reject `behavior` (1 exec) | yes |
| out of bounds | off 999999 | reject `bounds` (0 exec) | `ngb-patch` reject (0 exec) | no, `ngb-patch` already blocks |
| correct value, wrong position | off 151, 34→33 | reject `position_mismatch` (0 exec) | reject `stdout` (1 exec) | yes |

Measured 2026-06-05. Four of four bad classes are rejected before any ELF runs when both `--expect-off` and `--expect-new` are derived from the conf spec.

- **Proven.** The static gate rejects value, position, target-type, and bounds errors at author time, with zero executions. Auditor-only catches value, position, and target errors only after running the ELF (bounds is already blocked by `ngb-patch`).
- **Intent binding is two-part.** Value alone was insufficient. Position plus value, both computed from the spec, closes the last gap.

The product claim is **pre-execution rejection of operational errors** (deterministic, gated in CI), not agent retry-count reduction.

## Relation to raw `ngb-patch`

Raw pairs expose offset encoding to the agent. Micro-ops name the intent class; the tool derives the pair. Agents emit `kind=rodata_byte_write` instead of `--off 152 --pair 32:33`.
