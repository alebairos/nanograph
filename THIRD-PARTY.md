# Third-party code

## Stanford GraphBase (G33)

Donald E. Knuth, *The Stanford GraphBase: A Platform for Combinatorial Computing* (ACM Press / Addison-Wesley, 1993). Public-domain sources via Stanford and mirrors such as https://github.com/ascherer/sgb.

G33 does not ship or run SGB sources. `fixtures/metamorphic/knuth_sgb.c` is a NanoGraph-authored driver that models the page-414 `save_graph` erratum (`fopen` `"w"` vs `"wb"`) so the backtest pipeline can exercise a synthetic third domain. See `fixtures/backtest/knuth-sgb/CASE.md`. A future G35 will run Knuth's actual `gb_flip`+`rand_len` arithmetic (the page-388 off-by-one) without simulation.

## Stanford GraphBase / GB_FLIP (G35)

The Stanford GraphBase by Donald E. Knuth, mirror https://github.com/ascherer/sgb . `fixtures/metamorphic/knuth_rand_len.c` vendors Knuth's GB_FLIP generator (`gb_flip.w`) and the `rand_len` draw (`gb_rand.w`), transcribed from `ascherer/sgb` at `fd99287`, with the real `rand_len` off-by-one (span `max_len-min_len` vs the fix `65433e2` adding `+1`). The generator arithmetic is Knuth's, validated against his `test_flip` constants; `_start`, the argv parse, and print are our trusted driver. Unlike G33, this runs Knuth's actual bytes. See `fixtures/backtest/knuth-rand-len/CASE.md`.

## WABT (G34)

The WebAssembly Binary Toolkit, https://github.com/WebAssembly/wabt , Apache-2.0. `fixtures/metamorphic/wabt_leb128.c` is a freestanding C transcription of `ReadU64Leb128` from `src/leb128.cc` and its real too-big-u64 mask bug (`0xf0` vs `0xfe`, fix `f1f3d6d` / PR #2256, buggy parent `89582f5`). It is not a verbatim build of wabt's C++. The decode arithmetic, masks, and bug are wabt's; `_start`, the hex parse, and print are our trusted driver. See `fixtures/backtest/wabt-leb128/CASE.md`.

## Cap'n Proto / kj (G39)

Cap'n Proto, https://github.com/capnproto/capnproto . `fixtures/metamorphic/capnproto_base64.c` is a freestanding C transcription of libb64-derived base64 encode/decode from `c++/src/kj/encoding.c++` (public-domain libb64 core). Parent `9306bc0` silently skipped invalid and padding bytes; fix `f3e0ed2` (PR #595) reports `hadErrors`. The permissive skip-invalid loop and the strict WHATWG-aligned checks are capnproto's; `_start`, argv parse, and print are our trusted driver. See `fixtures/backtest/capnproto-base64/CASE.md`.

## Bit Twiddling Hacks (G26)

Sean Eron Anderson, public-domain "Reverse bits in parallel" routine, vendored verbatim in `fixtures/metamorphic/reverse32.c`. See `docs/adr/ADR-009-real-vendored-code.md`.
