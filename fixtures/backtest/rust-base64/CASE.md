# Rust base64 InvalidLastSymbol real-history backtest (G56)

First Rust language-diversity backtest. `marshallpierce/rust-base64` `decode_helper` stage 4.

## The bug

When the last non-padding symbol encodes trailing bits that will be discarded, the parent accepts the input. Fix `f6915a3` (parent `95edf364`, PR #293) adds `InvalidLastSymbol`.

| Revision | behavior |
| --- | --- |
| buggy parent | accepts `iYV=` (trailing 01 in last sextet) |
| fix | rejects with `InvalidLastSymbol` |

Upstream: https://github.com/marshallpierce/rust-base64

## Faithfulness

`fixtures/metamorphic/rust_base64.c` transcribes stage 4 leftover decode from `decode.rs` into freestanding C behind a trusted driver. The `InvalidLastSymbol` mask check matches the fix diff. `mint-backtest.sh` strips `#if !defined(INVALID_LAST_CHECK)` for rev2.

## Pre-registered property

`round_trip` via `fixtures/metamorphic/rust_base64.req`. Witness `hex=6959563d` (`iYV=`). Buggy rev2 decodes silently, re-encodes to `iYU=` != `iYV=`. Honest rev rejects.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/rust_base64.c INVALID_LAST_CHECK \
  fixtures/backtest/rust-base64 fixtures/metamorphic/rust_base64.req invalidlast
```

## Result

Catch. Timeline accept → reject (`hex=6959563d`) → accept. Fix returns to revision one's `graph_root_hash`.
