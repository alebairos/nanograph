# zig std Wyhash iterative real-history backtest (G57)

First language-diversity backtest using `flow_composition` on mined real history. Validates G69 beyond modeled CA.

## The bug

`ziglang/zig` `lib/std/hash/wyhash.zig`, `Wyhash.update`. When input crosses a 48-byte block boundary and the remainder is fewer than 16 bytes, the parent omits copying the preceding 16-byte tail into the internal buffer before `final`. Fix PR #16696 (`f3fbdf2b`, parent `90fde14c`).

| Revision | behavior |
| --- | --- |
| buggy parent | incremental update drops last-16 tail when `len>=48` and remainder `<16` |
| fix | copy `input[i-16..i]` into `buf[48-16..]` before remainder |

Upstream: https://github.com/ziglang/zig

## Faithfulness

`fixtures/metamorphic/zig_wyhash.c` transcribes Wyhash from `wyhash.zig` into freestanding C behind a trusted driver. The tail-copy guard matches the fix diff. `mint-backtest.sh` strips `#if !defined(WYHASH_TAIL_FIX)` for rev2 and compiles with `-DWYHASH_TAIL_FIX` so the buggy parent path is selected.

The driver uses deterministic bytes from `orig_seed` and a `flow` argv protocol aligned with `flow_composition`:

- `flow(58, seed)` one-shot hash of 58 bytes
- `flow(48, seed)` partial update, prints decimal state token (leading `2`)
- `flow(10, token)` continue 10 bytes and finalize

`PARTIAL_N=48` matches pre-registered probes in `gen_zig_wyhash`.

## Pre-registered property

`flow_composition` via `fixtures/metamorphic/zig_wyhash.req`. Witness `hex=5` (seed for triple `48 10 5`). Buggy rev2 disagrees on one-shot vs incremental final hash.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/zig_wyhash.c WYHASH_TAIL_FIX \
  fixtures/backtest/zig-wyhash fixtures/metamorphic/zig_wyhash.req tailfix
```

## Result

Catch. Timeline accept, reject (`hex=5`), accept. Fix returns to revision one's `graph_root_hash`.
