# Third-party code

## Stanford GraphBase (G33)

Donald E. Knuth, *The Stanford GraphBase: A Platform for Combinatorial Computing* (ACM Press / Addison-Wesley, 1993). Public-domain sources via Stanford and mirrors such as https://github.com/ascherer/sgb.

G33 does not ship or run SGB sources. `fixtures/metamorphic/knuth_sgb.c` is a NanoGraph-authored driver that models the page-414 `save_graph` erratum (`fopen` `"w"` vs `"wb"`) so the backtest pipeline can exercise a synthetic third domain. See `fixtures/backtest/knuth-sgb/CASE.md`. A future G35 will run Knuth's actual `gb_flip`+`rand_len` arithmetic (the page-388 off-by-one) without simulation.

## Bit Twiddling Hacks (G26)

Sean Eron Anderson, public-domain "Reverse bits in parallel" routine, vendored verbatim in `fixtures/metamorphic/reverse32.c`. See `docs/adr/ADR-009-real-vendored-code.md`.
