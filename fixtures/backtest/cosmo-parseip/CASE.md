# cosmo ParseIp real-history backtest (G41)

First Justine-stack follow-through after G40 shortlist. It runs cosmopolitan's actual `ParseIp` arithmetic and its real overflow bug on real inputs, native on the Linux runner.

## The bug

`jart/cosmopolitan` `net/http/parseip.c`, `ParseIp`. Before the fix, octet digits accumulated with `b *= 10; b += digit` and no overflow guard. The last octet of `255.255.255.256` wraps to `4294967040` (`0xFFFFFFF00`) instead of failing. Fix `c995838` (parent `539bddc`) adds `__builtin_mul_overflow`, `__builtin_add_overflow`, and `(b > 255 && dotted)` checks.

| Revision | SHA | behavior |
| --- | --- | --- |
| buggy parent | `539bddc` | silent wrong u32 on overflow |
| fix | `c995838` | returns failure on overflow |

Upstream: https://github.com/jart/cosmopolitan

## Faithfulness and its limit

`fixtures/metamorphic/cosmo_parseip.c` transcribes `ParseIp` into freestanding C. The digit loop and overflow checks are cosmopolitan's; `_start`, argv parse, and print are our trusted driver. The fix is a strippable `add_digit` dispatcher; `mint-backtest.sh` strips the strict path and compiles rev2 with `-DIP_OVERFLOW_OK`.

## Pre-registered property

`value_oracle` via `fixtures/metamorphic/cosmo_parseip.req`. Six probe pairs in `gen_cosmo_parseip`; witness `255.255.255.256` (`hex=3235352e3235352e3235352e323536`). Buggy rev returns `4294967040`; honest rev returns `REJECT`.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/cosmo_parseip.c IP_OVERFLOW_OK \
  fixtures/backtest/cosmo-parseip fixtures/metamorphic/cosmo_parseip.req overflow
```

## Result

Catch. Timeline accept, reject (`hex=3235352e3235352e3235352e323536`), accept. Fix returns to revision one's `graph_root_hash`.
