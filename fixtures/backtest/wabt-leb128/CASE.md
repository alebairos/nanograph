# wabt ReadU64Leb128 real-history backtest (G34)

The first true real-history backtest. It runs wabt's actual decode arithmetic and its real mask bug on real inputs, native on the Linux runner, with no simulation. Contrast G33, which modeled a Windows-only erratum the runner cannot observe.

## The bug

wabt `src/leb128.cc`, `ReadU64Leb128`. The 10th byte of a u64 LEB128 may set only bit 0 (u64 bit 63); higher bits overflow u64. The overflow check used `p[9] & 0xf0`, copied from the u32 path, which misses bits 1..3 (`0x0e`). A 10-byte LEB128 above u64 max was silently accepted and truncated. Fix #2256 changes the mask to `0xfe`.

```
buggy:  if (p[9] & 0xf0) return 0;   // "values > 32 bits" (copy-paste)
fix:    if (p[9] & 0xfe) return 0;   // values > 64 bits
```

| Revision | SHA | mask |
| --- | --- | --- |
| buggy parent | `89582f5` | `0xf0` |
| fix | `f1f3d6d` (PR #2256) | `0xfe` |

Upstream: https://github.com/WebAssembly/wabt , fix commit `f1f3d6dc2c0007a8436a187dfccc45af050741d1`.

## Faithfulness and its limit

`fixtures/metamorphic/wabt_leb128.c` transcribes wabt's `ReadU64Leb128` decode (the `BYTE_AT`/`LEB128_n` accumulation, the per-byte continuation, the 10th-byte overflow check) into freestanding C. The masks and the bug are wabt's. The fix is expressed as a strippable block: a base `0xf0` check both revisions keep, plus a `0x0e` block the honest revisions add (`0xf0 | 0x0e == 0xfe`), which `mint-backtest.sh` removes for the buggy revision.

This is not a verbatim build of wabt's C++. wabt's `leb128.cc` depends on wabt headers and is not freestanding, so a byte-for-byte vendor would pull in libc++ and the wabt type system. The honest claim is a faithful transcription of the function under test behind a trusted driver (`_start`, hex parse, print), the same trusted-driver standard as G26.

## Pre-registered property

`round_trip` via `fixtures/metamorphic/wabt_leb128.req`: `enc(dec(b)) == b` for accepted `b`. The wire is the LEB128 byte string as lowercase hex (`wire=hex`), so a full 10-byte u64 LEB128 fits one argv token, unlike the `0x01`-packed integer wire of the utf8/leb128 cases.

Witness `ffffffffffffffffff02`. The buggy revision accepts it and decodes to `9223372036854775807` (truncated); `enc` of that is the 9-byte `ffffffffffffffff7f`, which differs, so round_trip rejects. The honest revision rejects the input outright. Verified directly: buggy `dec` returns the truncated value, honest `dec` returns `REJECT`, both accept u64 max `ffffffffffffffffff01`.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/wabt_leb128.c WABT_BUG \
  fixtures/backtest/wabt-leb128 fixtures/metamorphic/wabt_leb128.req toobig
```

## Result

Catch. Timeline accept, reject (`hex=ffffffffffffffffff02`), accept. Fix returns to revision one's `graph_root_hash`.
