# Rust base64 InvalidLastSymbol native lang-pack backtest (G56)

**real-history** (not synthetic). Native no_std Rust port of `marshallpierce/rust-base64` `decode_helper` stage 4, minted via `mint-one-rust.sh`. Same provenance as `fixtures/backtest/rust-base64/CASE.md`.

## The bug

When the last non-padding symbol encodes trailing bits that will be discarded, the parent accepts the input. Fix `f6915a3` (parent `95edf364`, PR #293) adds `InvalidLastSymbol`.

| Revision | behavior |
| --- | --- |
| buggy parent | accepts `iYV=` (trailing 01 in last sextet) |
| fix | rejects with `InvalidLastSymbol` |

Upstream: https://github.com/marshallpierce/rust-base64

## Faithfulness

`fixtures/metamorphic/rust_native_base64.rs` ports stage 4 leftover decode from the C transcription into freestanding no_std Rust behind the trusted driver. rev2 uses `--cfg disable_invalid_last_check` (same guard semantics as C `-DINVALID_LAST_CHECK` / stripped `#if !defined(INVALID_LAST_CHECK)`).

## Pre-registered property

`round_trip` via `fixtures/metamorphic/rust_base64.req`. Witness `hex=6959563d` (`iYV=`). Buggy rev2 decodes silently, re-encodes to `iYU=` != `iYV=`. Honest rev rejects.

## Mint

```
./scripts/mint-lang-pack-native-backtest.sh rust-base64 fixtures/backtest/rust-base64-native
```

## Result

Catch. Timeline accept → reject (`hex=6959563d`) → accept. Fix returns to revision one's `graph_root_hash`.
