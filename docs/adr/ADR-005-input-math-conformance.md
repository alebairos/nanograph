# ADR-005 — Input-bound math conformance

**Status:** Accepted (**Runtime operands via argv; multi-case conformance**)
**Date:** 2026-06-06
**Goal:** G21 (issue #41)

## Context

Every conformance specimen through G20 bakes operands into the spec. `add(1,1)`, `op=eca rule=110 width=96 gens=96 init=right`. The binary is verified as a constant realization of a constant intent. Real agent-produced programs are functions of runtime inputs. The claims ledger parked "Runtime operands in ConfSpec" until an intent must reference execution inputs.

## Decision

Add `input=argv` to `ConfSpec` and `op=gcd` to `conf-eval`. Runtime operands are passed as extra CLI args to both `conf-eval` and the ELF runner. Verify conformance across a cases file of `(a, b, expected)` vectors. Ship two Route B optimization variants plus a near-miss negative.

## Negative quality (G22)

The first negative returned `a+b` and diverged on every case, so it never exercised the multi-case dimension and was not a believable gcd miscompilation. It is replaced by a near-miss: Euclid's loop degraded to a single `if`, correct only when `b` divides `a`. The conformance gate asserts the near-miss accepts at least one case and rejects at least one, encoding the claim that input-binding catches bugs single-sample verification misses.

## Why the adjacent lower layer is insufficient

`conf-eval` parsed fixed `a` and `b` from the spec file. A function-of-inputs program cannot be verified without binding inputs at execution time. The smallest mechanism is `input=argv` on the spec plus extra args on `conf-eval` and `run-linux-elf-capture.sh`. No new floor tier; same stdout-diff verdict as G17.

## What we are not building

- No `.ngb` format change. I1–I6 hold.
- No stdin input mode (v0 is argv only).
- No general math library (v0 is `gcd` only).
- No recompilation in CI. Binaries minted once, committed.
- No symbolic or all-inputs proof.

## Design

- `ConfSpec`: `op=gcd input=argv yield=stdout`.
- `conf-eval gcd.spec 12 18` prints `6\n` via Euclidean algorithm.
- `run-linux-elf-capture.sh gcd_v1.ngb 12 18` captures program stdout.
- Phase 1 oracle gate: each line in `gcd.cases` matches `conf-eval` output.
- Phase 2 conformance gate: each case accepts on v1 and v2 (distinct hash), rejects on wrong specimen.

## Known limit

The floor is still sampled. The cases file fixes finitely many inputs. Richer than one constant, weaker than symbolic equivalence. The oracle stays cheap (Euclidean gcd in C).

## Kill trigger

If runtime operand binding requires a general interpreter or dynamic spec evaluation at agent speed, stop extending input modes.
