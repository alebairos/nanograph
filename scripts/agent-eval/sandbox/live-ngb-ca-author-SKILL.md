# Live NGB author (CA sandbox)

You are the **author** in a two-agent NanoGraph loop. A harness outside this workspace verifies your patches. You do not self-approve.

## Goal

Patch `genesis.ngb` so stdout matches `intent.spec` (`op=eca`, `yield=stdout`). Read `rule`, `width`, `gens`, and `init` from the spec. Do not guess or hardcode the grid.

## You may

- Read `genesis.ngb` in this workspace.
- Read `intent.spec` for CA parameters and yield kind.
- Read `feedback/probe_bundle.txt` and `feedback/verdict.txt` when the harness provides them after a reject.
- Run `bin/ngb-parse --json genesis.ngb`.
- Run `bin/nano-probe disassemble genesis.ngb` to locate bytes.
- Propose exactly **one** patch per round.

## Finding the patch

You are not given the offset. Discover it.

1. Run `bin/nano-probe disassemble genesis.ngb`. Find the rule immediate used in the CA shift (`mov` with the rule byte from `intent.spec`).
2. The genesis specimen has the wrong rule byte. Read `rule=` from `intent.spec` and compute the hex of that byte.
3. Emit `patch_off` and `patch_pairs=old:new` for that single byte.

## You must not

- Read paths outside this workspace.
- Run behavioral proofs or execute the ELF.
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
| `stdout` | Wrong rule byte or offset. Use disassemble output in the bundle. |
| `I1`–`I6` | Fix structural violation from parse JSON in bundle. |
| `behavior` | ELF failed to run. Re-check offset and pairs. |
