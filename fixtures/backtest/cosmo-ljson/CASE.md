# cosmo ljson overlong UTF-8 real-history backtest (G42)

Second Justine-stack follow-through after G40. It runs cosmopolitan's actual ljson string-decode classification and its real validation gap on real inputs, native on the Linux runner. The real-history analogue of the synthetic G27 overlong demo.

## The bug

`jart/cosmopolitan` `tool/net/ljson.c`. Before the fix, the JSON string-body loop copied any byte above `0x1F` verbatim with no UTF-8 validation, so overlong, surrogate, and malformed sequences passed straight into the decoded string. Fix `baf51a4` ("Add utf-8 validation to ljson", parent `ccd057a`) adds the `kJsonStr[256]` classifier and rejects overlong (`0xC0`/`0xC1` leads, `E0 < A0`, `F0 < 90`), surrogate (`ED >= A0`), and malformed continuation bytes.

| Revision | SHA | behavior |
| --- | --- | --- |
| buggy parent | `ccd057a` | copies invalid UTF-8 verbatim |
| fix | `baf51a4` | rejects invalid UTF-8 |

Upstream: https://github.com/jart/cosmopolitan

## Why value_oracle, not round_trip

The scorecard first proposed `round_trip`. That relation cannot catch this bug. The buggy decoder copies string bytes verbatim, so `encode(decode(b)) == b` holds for `c0 80`, the pass-through is the identity. The defect is an acceptance bug, the honest revision rejects invalid UTF-8 and the buggy one accepts it. `value_oracle` separates that directly, the same relation G41 used. Same witness, same timeline.

## Faithfulness and its limit

`fixtures/metamorphic/cosmo_ljson.c` transcribes the `kJsonStr` table and the raw-byte UTF-8 validation paths into freestanding C. The classifier and continuation checks are cosmopolitan's; `_start`, hex argv decode, and print are our trusted driver. The fix is the strippable honest decoder; `mint-backtest.sh` drops it and compiles rev2 with `-DLJSON_NOUTF8`, which selects the verbatim-copy parent path.

Input domain is raw string-body bytes only. JSON escapes (`\\`, `\\uXXXX`) and the CESU-8 surrogate-pair merge are out of the domain, since the bug under test lives in raw multibyte UTF-8 validation.

## Pre-registered property

`value_oracle` via `fixtures/metamorphic/cosmo_ljson.req`, `wire=hex`. Six probe pairs in `gen_cosmo_ljson`. Valid ASCII and 2/3/4-byte UTF-8 round-trip canonically; two rejection witnesses cover overlong and surrogate.

| Witness input | hex | Class | Buggy rev | Honest rev |
| --- | --- | --- | --- | --- |
| overlong U+0000 | `c080` | `EVILUTF8` lead `0xC0` (timeline gate) | `c080` | `REJECT` |
| surrogate U+D800 | `eda080` | `UTF8_3_ED`, second byte `>= 0xA0` | `eda080` | `REJECT` |

`c080` is the backtest timeline reject hex.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/cosmo_ljson.c LJSON_NOUTF8 \
  fixtures/backtest/cosmo-ljson fixtures/metamorphic/cosmo_ljson.req ljson-overlong
```

## Result

Catch. Timeline accept, reject (`hex=c080`), accept. Fix returns to revision one's `graph_root_hash` (`24814448a6c0`).
