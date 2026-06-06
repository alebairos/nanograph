# Live NGB author (sandbox)

You are the **author** in a two-agent NanoGraph loop. A harness outside this workspace verifies your patches. You do not self-approve.

## Goal

Patch `genesis.ngb` so stdout matches `intent.spec` (`yield=stdout`). Sum operands `a` and `b` from the spec. Do not guess or hardcode the answer.

## You may

- Read `genesis.ngb` in this workspace.
- Read `intent.spec` for operands and yield kind.
- Read `feedback/probe_bundle.txt` and `feedback/verdict.txt` when the harness provides them after a reject.
- Run `bin/ngb-parse --json genesis.ngb`.
- Run `bin/nano-probe disassemble genesis.ngb` to locate rodata bytes.
- Propose exactly **one** patch per round.

## Finding the patch

You are not given the offset. Discover it.

1. Run `bin/nano-probe disassemble genesis.ngb`. Rodata shows as `db 0x..` with `image_offset`.
2. Find the digit byte you must change.
3. Compute the new byte from `intent.spec`. Sum `a` and `b`, render the decimal string, take the ASCII hex of the digit you change.
4. Emit `patch_off` and `patch_pairs=old:new` for that byte.

## You must not

- Read paths outside this workspace.
- Run behavioral proofs or execute the ELF.
- Patch instruction bytes. Target rodata only.
- Emit more than one patch per round.
- Run `ngb-patch`. The harness applies your proposal.

## Emit format (required)

```text
patch_off=<u32 image offset you discovered>
patch_pairs=<old_hex>:<new_hex>
```

Fill from your own discovery. Do not copy literal offsets or bytes from this skill.

## On reject

Read `feedback/verdict.txt` and `feedback/probe_bundle.txt`. Fix from invariant and detail. Do not retry the same patch unchanged.

| Invariant | Action |
| --- | --- |
| `stdout` | Wrong value or offset. Use disassemble output in the bundle. |
| `not_rodata` / `value_mismatch` / `position_mismatch` | Static gate failed. Fix offset or digit. |
| `I1`–`I6` | Fix structural violation from parse JSON in bundle. |
| `behavior` | ELF failed to run. Re-check offset and pairs. |
