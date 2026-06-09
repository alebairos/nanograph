# Real Knuth canon backtest: rand_len off-by-one (G35)

The first backtest that runs Knuth's actual canon. It executes the real GB_FLIP generator and the real `rand_len` draw, native on the Linux runner, no simulation. Contrast G33, which modeled a Knuth-shaped erratum the runner could not observe, and G34, which transcribed a third-party (wabt) function. Here the arithmetic under test is Knuth's own.

## The bug

Stanford GraphBase `gb_rand.w`, the `rand_len` macro. It draws a random length in `[min_len, max_len]`, but the span passed to `gb_unif_rand` was `max_len - min_len`, which yields `[min_len, max_len-1]` and never reaches `max_len`. The fix adds `+1`.

```
buggy:  min_len + gb_unif_rand(max_len - min_len)
fix:    min_len + gb_unif_rand(max_len - min_len + 1)
```

`gb_unif_rand(m)` returns a uniform value in `[0, m-1]`, so the buggy span is one short. The defect is silent: generated graphs still look valid, the longest possible edge length is simply never drawn.

| Revision | SHA | span |
| --- | --- | --- |
| buggy | `fd99287` | `max_len - min_len` |
| fix | `65433e2` | `max_len - min_len + 1` |

Upstream mirror: https://github.com/ascherer/sgb , `gb_rand.w`. Errata documented in Knuth's SGB errata (the "embarrassing off-by-one").

## Faithfulness

`fixtures/metamorphic/knuth_rand_len.c` vendors Knuth's GB_FLIP (`gb_flip.w`: `gb_init_rand`, `gb_flip_cycle`, `gb_unif_rand`, the `gb_next_rand` macro) and the `rand_len` draw, transcribed from `ascherer/sgb` at `fd99287`. The generator arithmetic is Knuth's verbatim. It is validated against his own `test_flip` constants: `gb_init_rand(-314159)` then `gb_next_rand() == 119318998`, and after 133 further draws `gb_unif_rand(0x55555555) == 748103812`. `_start`, the argv parse, and print are our trusted driver.

The `+1` fix is a strippable block: the driver computes `span = max_len - min_len` and, under `#if !defined(RAND_LEN_BUG)`, adds `span += 1`. `mint-backtest.sh` drops that block for the buggy revision. The compile constants are `MIN_LEN=1`, `MAX_LEN=10`.

## Pre-registered property

A new relation, `range_coverage`, in `fixtures/metamorphic/knuth_rand_len.req`. Neither `round_trip` nor `involution` fits a generator. The relation sweeps gb_flip seeds, each a `gb_init_rand(seed)` plus one `rand_len` draw, and asserts the observed `[min, max]` equals the declared `[lo, hi]`. The driver stays a pure generator; the verifier aggregates the sweep, so the relation is reusable for any bounded generator.

**Reachability phase (G37/G38).** `knuth_rand_len.req` sets `reachability=on`, `lo_seed=22`, `hi_seed=2`. Isolated draws verify `draw(22)==1` and `draw(2)==10`. Deterministic. Reject names `phase=reachability`.

**Containment phase (G38).** `containment=sweep` runs after reachability. 256 seeds swept; observed min/max must equal `[1,10]`. Sampled bound check for over-reach. Reject names `phase=containment`.

**Catch.** Buggy revision fails `phase=reachability` first (`draw(22)` yields 2, not 1), witness `hex=02`. `rev2_offbyone` is the span-minus-one mutant from `mint-backtest.sh` (`RAND_LEN_BUG`). Sweep alone would also catch it (max 9), but reachability fails first with an explicit witness.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/knuth_rand_len.c RAND_LEN_BUG \
  fixtures/backtest/knuth-rand-len fixtures/metamorphic/knuth_rand_len.req offbyone
```

## Result

Catch. Timeline accept, reject (`hex=02`, `endpoint=lo seed=22 got=2 want=1`), accept. Fix returns to revision one's `graph_root_hash`.
