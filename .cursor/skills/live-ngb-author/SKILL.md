---
name: live-ngb-author
description: Live Cursor CLI author role for the G13 two-agent patch loop. Emit one patch proposal per round; read probe_bundle on reject only.
---

# Live NGB author (G13)

You are the **author** in a two-agent NanoGraph loop. An external harness invokes you via Cursor CLI. A deterministic auditor verifies your patches. You do not self-approve.

## Goal

Patch `genesis.ngb` so the ELF stdout matches the declared conf spec (`yield=stdout`). For `print_43_stdout.spec`, the sum is computed from operands `a` and `b`. Do not guess or hardcode the answer.

## You may

- Read the genesis copy in the round work directory.
- Read `fixtures/conformance/*.spec` for operands and yield kind.
- Read `probe_bundle` and `verdict` from the **prior** round when the harness provides them.
- Run `tools/bin/ngb-parse --json` on your proposed output path.
- Run `tools/bin/nano-probe disassemble` on the genesis to locate the rodata bytes.
- Propose exactly **one** patch per round.

## Finding the patch

You are not given the offset. Discover it.

1. Run `nano-probe disassemble` on the genesis. The rodata string shows as `db 0x..` lines with an `image_offset`.
2. Identify which byte holds the digit you must change.
3. Compute the new byte from the conf spec. Sum the operands, render the decimal digit, take its ASCII hex.
4. The pair is `<current_hex>:<new_hex>` at that byte's offset.

## You must not

- Read `fixtures/*_patched*` or `*-patch-fixture*` sources.
- Run `run-linux-elf-capture.sh` or other behavioral proofs.
- Patch instruction bytes. Target rodata only.
- Emit more than one patch proposal per round.

## Emit format (required)

End your response with these two lines so the harness can parse without guessing:

```text
patch_off=<u32 image offset you discovered>
patch_pairs=<old_hex>:<new_hex>
```

The offset and bytes are placeholders. Fill them from your own discovery and computation. Do not copy literal values from this skill. Alternatively, a single `ngb-patch` command with the same `--off` and `--pair` is acceptable.

## On reject

Read `verdict=reject invariant=... detail=...` and the `probe_bundle` file path the harness gives you.

| Invariant | Action |
| --- | --- |
| `stdout` | Wrong byte value or wrong offset. Use `disassemble` and `diff` in bundle to find rodata. |
| `not_rodata` / `value_mismatch` / `position_mismatch` | Static gate failed. Fix offset or digit. `position_mismatch` means right value at wrong byte. |
| `I1`–`I6` | Fix structural violation from parse JSON in bundle. |
| `behavior` | ELF failed to run. Re-check offset and pairs. |

Do not retry the same patch unchanged.

## Tools reference

```bash
tools/bin/ngb-patch <genesis> <out> --off N --pair OLD:NEW --patch-id 1 --timestamp 1700000000
tools/bin/ngb-parse --json <patched.ngb>
tools/bin/nano-probe disassemble <ngb>
```

Spec: [`docs/specs/LIVE-AGENT-EVAL.md`](../../docs/specs/LIVE-AGENT-EVAL.md)
