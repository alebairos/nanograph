# Synthetic Knuth-shaped portability backtest (G33)

This case does NOT run Knuth's bytes. It is a NanoGraph-authored driver that models the Stanford GraphBase `save_graph` erratum so the existing `round_trip` backtest pipeline can exercise a third domain. The SGB SHAs below are provenance for the modeled bug, not inputs to the proof. The real-Knuth-canon backtest is G35 (`rand_len` off-by-one), which runs Knuth's actual arithmetic.

## Erratum

Knuth, *The Stanford GraphBase*, page 414 (December 2025).

`save_graph` opened the output file with `fopen(f,"w")`. On Windows-like systems, text mode expands each internal `\n` to `\r\n` on disk. A graph saved on Windows could not be `restore_graph` on Linux. The fix changes the mode to `fopen(f,"wb")`.

Official erratum: https://www-cs-faculty.stanford.edu/~knuth/sgb.html

## Source mirror

Andreas Scherer's mirror of Knuth's releases: https://github.com/ascherer/sgb

| Revision | SHA | `fopen` in `gb_save.w` |
| --- | --- | --- |
| buggy parent | `c0943fd` | `"w"` |
| fix | `88fac2f` | `"wb"` |

## Trusted driver (not full SGB)

Vendoring all of SGB behind a freestanding driver would pull in graphbase, literate-program build, and libc. G33 models only the erratum semantics in `fixtures/metamorphic/knuth_sgb.c`.

- `save` serializes a `0x01 ++ payload` graph blob.
- Honest revisions use binary save (one output byte per payload byte).
- The buggy revision expands `0x0A` to `0x0D 0x0A`, modeling Windows text mode.
- `restore` reads serialized bytes literally with no CRLF normalization, modeling Linux reading a Windows text-mode file.

## Pre-registered property

`round_trip` via `fixtures/metamorphic/knuth_sgb.req`: `restore(save(b)) == b` over domain `knuth_sgb`.

Witness on the buggy revision: probe `266` (`0x01 0x0A`), hex `0A`.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/knuth_sgb.c BUGGY_TEXTMODE \
  fixtures/backtest/knuth-sgb fixtures/metamorphic/knuth_sgb.req textmode
```

## Result

Catch. Timeline reads accept, reject (`hex=0A`), accept. Fix returns to revision one's `graph_root_hash`.
