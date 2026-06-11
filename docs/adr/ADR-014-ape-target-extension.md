# ADR-014 — APE target extension spike

**Status:** Accepted (spike verdict)
**Date:** 2026-06-11
**Goal:** G54 (#71)

## Context

ADR-010 states NanoGraph is target-bound (freestanding x86_64 Linux ELF today). Cosmopolitan APE promises one binary loadable across OS loaders on the same ISA.

## Spike verdict (G54)

| Hypothesis | Result | Product implication |
| --- | --- | --- |
| H1 harness APE build | **INCONCLUSIVE** | cosmocc absent on spike host |
| H2 witness cross-loader | **INCONCLUSIVE** | No APE specimens minted |
| H3 `.ngb` on APE bytes | **PARTIAL** | Linux ELF parse clean; APE polyglot untested |
| H4 real portability bug | **REFUTED** | No FIT candidate; G33 modeled case stands |

**Decision:** **reject** as a verification extension. Keep Linux ELF + qemu/Docker runner. Do not open G60–G62. Optional future **tooling-only** revisit if cosmocc is pinned and H1 is re-run.

## What we are not building

- No multi-arch.
- No APE runner in `check-all-proofs.sh`.
- No format change unless a future H3 kill on APE bytes opens a separate ADR.

## Kill trigger met

H4 found no FIT candidate after scoped mining attempt. Publish kill report in `APE-TARGET-SPIKE.md`. Restore parked trigger in NANO-GOALS for APE until new evidence.

## Addendum 2026-06-11 (#85): tooling-only revisit condition met

The optional revisit named in the decision happened. cosmocc 14.1.0 pinned under `spike/ape/`; H2 witness parity recorded on one utf8 probe; H1 re-run is **PROVEN**: `check-input-math-conformance.sh` passes on macOS arm64 with `conf-eval`, `ngb-parse`, `ngb-extract` as APE binaries behind env seams (native 3026 ms, APE 4145 ms). Evidence in `APE-TARGET-SPIKE-FOLLOWON.md`.

Scope of the move: the **tooling tier only**. Contributors off-Linux can run harness tools without a local C toolchain. The verification-extension **reject stands**. G60–G62 stay closed. No APE runner enters `check-all-proofs.sh`.
