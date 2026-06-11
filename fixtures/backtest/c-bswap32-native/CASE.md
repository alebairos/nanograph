# C lang-pack native bswap32 backtest (G77)

Timeline reuses committed G24 metamorphic mints (`bswap32.ngb` honest, `bswap32_evil.ngb` rotl8). Proves the C pack's committed artifacts satisfy accept → reject (`x=1`) → accept under `bswap32.req` without re-minting in CI.

Mint (refresh copies only):

```
./scripts/mint-lang-pack-bswap32-backtest.sh c fixtures/backtest/c-bswap32-native
```
