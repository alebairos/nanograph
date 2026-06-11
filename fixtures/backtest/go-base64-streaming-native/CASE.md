# Go base64 streaming native lang-pack backtest (G58)

**real-history** (not synthetic). Native Go port of `golang/go` `encoding/base64` RawURLEncoding streaming decode, minted via `mint-one-go.sh`. Same provenance as `fixtures/backtest/go-base64-streaming/CASE.md`.

Parent `8971d618` `Decoder.Read` returned EOF on NoPadding tail fragments; fix `20d745c` decodes final `nbuf<4` fragment (#13384).

## Property

`flow_composition` via `fixtures/metamorphic/go_base64_streaming.req`. Probe `AAAAAA` (seed 5). One-shot decode length 4 vs streaming partial+continue length 3 on buggy rev2.

Witness `hex=5`.

## Faithfulness

`fixtures/metamorphic/go_native_base64_streaming.go` ports the C transcription into static Go. Tail fix lives in `go_native_base64_streaming_tail.go` (`//go:build !notail`); rev2 uses `--tags notail` (same guard semantics as C `-DGO_BASE64_TAIL_FIX`).

## Mint

```
./scripts/mint-lang-pack-native-backtest.sh go-base64-streaming fixtures/backtest/go-base64-streaming-native
```

## Result

Catch. Timeline accept → reject (`hex=5`) → accept.

## Git history note

These `.ngb` files are fresh mints, not renames from prior synthetic bswap32 timelines. Go revisions are ~1.5MB each (full runtime). Witness fidelity vs the C-mined case is checked by `check-native-port-fidelity.sh`.
