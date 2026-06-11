# Rust crc32fast combine len2=0 real-history backtest (G71)

Second Rust backtest. `srijs/rust-crc32fast` `combine()` with `flow_composition` on mined history. Validates G69 beyond modeled CA.

## The bug

`combine(crc1, crc2, len2=0)` should return `crc1`. Parent `cdbd51f` falls through to `crc1 ^ crc2`. Fix `724ceb6` early-returns `crc1`.

| Revision | `combine(0,1,0)` |
| --- | --- |
| buggy parent | `1` |
| fix | `0` |

Upstream: https://github.com/srijs/rust-crc32fast

## Faithfulness

`fixtures/metamorphic/rust_crc32fast_combine.c` transcribes `combine.rs` (`X2N_TABLE`, `multiply`, combine loop) into freestanding C. `mint-backtest.sh` strips `#if !defined(LEN2_ZERO_CHECK)` for rev2.

## Pre-registered property

`flow_composition` via `fixtures/metamorphic/rust_crc32fast_combine.req`. Probe triple `(0,0,5)` with seed 5 mapping to `crc1=0 crc2=1`. Buggy rev2 gives `once=1 composed=0`. Witness `hex=5`. Third probe `(0,0,13)` repeats the len2=0 path with `crc2=0`. Triple `(1,1,5)` is not used: the verifier passes the partial decimal output back as argv seed, and this driver maps every non-5 seed to `crc2=0`, so that triple rejects even the fixed revision.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/rust_crc32fast_combine.c LEN2_ZERO_CHECK \
  fixtures/backtest/rust-crc32fast-combine fixtures/metamorphic/rust_crc32fast_combine.req len2zero
```

## Result

Catch. Timeline accept → reject (`hex=5`) → accept.
