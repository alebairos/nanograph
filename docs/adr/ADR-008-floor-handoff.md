# ADR-008 — Floor handoff: relation pre-filter, value-oracle backstop

**Status:** Accepted (**The two floors compose; demonstrated on one artifact**)
**Date:** 2026-06-08
**Goal:** G25 (issue #45)

## Context

G24 added the metamorphic floor and stated it complements the G9-G23 value-oracle floor. That was prose. The imposter arm proved involution accepts a wrong function, but nothing showed the value oracle catching the same bytes. An asserted complementarity is not a demonstrated one.

## Decision

Demonstrate the handoff on one artifact. Add `op=bswap` to `conf-eval` so the value oracle can compute the expected byte swap. Point the existing conformance floor at the G24 fixtures. The honest `bswap32` accepts. The `bswap32_imposter` (outer-byte swap) rejects with a value witness. The same imposter, run through the G24 involution relation, accepts. One gate, both verdicts, same bytes.

## Why this is the right shape

The relation is the cheap necessary check. It needs no spec and no expected value, so it runs for free on any function that claims the property, but it passes an involution-but-wrong function. The value oracle is the expensive sufficient check. It needs a computed expected value (the cost), and it separates the imposter. Cheap-then-expensive is the layered defense: run the relation first to reject non-involutions for nothing, fall back to the oracle only where a value answer is required.

## Why the adjacent lower layer is insufficient

The metamorphic floor cannot separate two functions that share the relation. That is its ceiling, by construction, not a bug. The smallest mechanism that closes it is the value oracle that already exists for gcd and eca, extended by one op. No new tool, no new program, no new floor tier.

## Robustness

The gate reuses `run-linux-elf-capture.sh` (core-dump disabled, bounded). The emulated x86_64 backend on Apple Silicon throws transient segfaults on known-correct binaries; the value comparison is exact and a transient empty output reads as a reject, so the honest arm could flake. The cases are few and the honest binary is tiny, so a flake is rare; if it proves noisy, the same isolated-confirm guard from G23 applies. Observed once on an unrelated proof (`print-42-patched`, exit 139) during this work, not reproduced in isolation.

## What we are not building

- No `.ngb` format change. I1-I6 hold.
- No new conformance machinery. One `conf-eval` op, the existing floor.
- No claim the oracle is cheap. It is the expensive backstop; that is the point of the split.

## Design

- `conf-eval` `op=bswap`, single argv operand, prints the u32 byte swap in decimal matching the specimen.
- `fixtures/metamorphic/bswap32.spec` (`op=bswap input=argv yield=stdout`), `bswap32.cases` hand table.
- `scripts/check-bswap-value-oracle.sh`: oracle self-check, honest accepts all, imposter rejects with witness `x=256` (`got=256 want=65536`), relation accepts the same imposter.

## Known limit

The value oracle costs an expected value. For functions where that is as hard to compute as the function itself, only the relation floor is affordable, and its ceiling stands. The handoff narrows the gap; it does not remove the oracle ceiling.

## Kill trigger

If closing a relation's ceiling needs an oracle no cheaper than re-deriving the function, the relation floor is the only affordable check there; stop trying to back it with a value oracle and document the residual ceiling instead.
