# Third-party code

## Stanford GraphBase (G33)

Donald E. Knuth, *The Stanford GraphBase: A Platform for Combinatorial Computing* (ACM Press / Addison-Wesley, 1993). Public-domain sources via Stanford and mirrors such as https://github.com/ascherer/sgb.

G33 does not ship or run SGB sources. `fixtures/metamorphic/knuth_sgb.c` is a NanoGraph-authored driver that models the page-414 `save_graph` erratum (`fopen` `"w"` vs `"wb"`) so the backtest pipeline can exercise a synthetic third domain. See `fixtures/backtest/knuth-sgb/CASE.md`. A future G35 will run Knuth's actual `gb_flip`+`rand_len` arithmetic (the page-388 off-by-one) without simulation.

## WABT (G34)

The WebAssembly Binary Toolkit, https://github.com/WebAssembly/wabt , Apache-2.0. `fixtures/metamorphic/wabt_leb128.c` is a freestanding C transcription of `ReadU64Leb128` from `src/leb128.cc` and its real too-big-u64 mask bug (`0xf0` vs `0xfe`, fix `f1f3d6d` / PR #2256, buggy parent `89582f5`). It is not a verbatim build of wabt's C++. The decode arithmetic, masks, and bug are wabt's; `_start`, the hex parse, and print are our trusted driver. See `fixtures/backtest/wabt-leb128/CASE.md`.

## Bit Twiddling Hacks (G26)

Sean Eron Anderson, public-domain "Reverse bits in parallel" routine, vendored verbatim in `fixtures/metamorphic/reverse32.c`. See `docs/adr/ADR-009-real-vendored-code.md`.
