# Zig native Wyhash backtest (G59)

Language-blind proof specimen. Same `flow_composition` relation and witness as G57 transcription, but rev1/rev3 compile **native Zig** with vendored `wyhash_fix.zig` (fix `f3fbdf2b`) and rev2 uses `wyhash_bug.zig` (parent `90fde14c`).

## Mint

```
./scripts/mint-backtest-zig-native.sh fixtures/backtest/zig-wyhash-native \
  fixtures/metamorphic/zig_wyhash.req
```

Pinned toolchain: Zig 0.13.0 in Docker (`scripts/mint-one-zig.sh`). No verifier changes.

## Result

Catch. Witness `hex=5` (seed 5, triple 48+10). Timeline accept → reject → accept. rev1 == rev3 `graph_root_hash`.
