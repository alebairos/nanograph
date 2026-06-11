# Go base64 streaming real-history backtest (G58)

`golang/go` `encoding/base64` RawURLEncoding streaming decode. Parent `8971d618` `Decoder.Read` returned EOF on NoPadding tail fragments; fix `20d745c` decodes final `nbuf<4` fragment (#13384).

## Property

`flow_composition` via `fixtures/metamorphic/go_base64_streaming.req`. Probe `AAAAAA` (seed 5). One-shot decode length 4 vs streaming partial+continue length 3 on buggy rev2.

Witness `hex=5`.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/go_base64_streaming.c GO_BASE64_TAIL_FIX \
  fixtures/backtest/go-base64-streaming fixtures/metamorphic/go_base64_streaming.req tailfix
```

## Result

Catch. Timeline accept → reject (`hex=5`) → accept.
