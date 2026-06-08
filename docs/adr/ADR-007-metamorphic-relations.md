# ADR-007 — Metamorphic relations as oracle-free verification

**Status:** Accepted (**The relation is the oracle; first relation is involution**)
**Date:** 2026-06-08
**Goal:** G24 (issue #44)

## Context

Every floor through G23 computes the expected output from a spec (`conf-eval`). That referee is the cost. For most real functions a value oracle is as hard to build as the function, and when an agent writes both the code and the assertion on the code's own output, the test is circular.

Some functions carry a property that holds with no expected value named. A byte swap is its own inverse. An encode/decode round-trips. Sorting twice equals sorting once. These are metamorphic relations: a property over the composition of runs. The relation is the oracle.

## Decision

Verify a binary against a declared metamorphic relation, computing no expected output. The first relation is **involution**, `f(f(x)) == x`. The first specimen is a C-stdlib-shaped `bswap32`.

A language-neutral **VerificationRequest** (kv `.req`) declares `relation`, `entry`, `domain`, `eq`. The verifier reads the request, drives the binary, and renders a verdict. The request is the seam: a future language-aware layer identifies which functions claim which relations; NanoGraph stays language-blind and execution-grounded.

## Why the adjacent lower layer is insufficient

The G9-G23 floor compares one execution to a computed scalar. Involution is a composition over runs with no scalar to compute. The conformance gate cannot express "run twice, compare to the input". The smallest mechanism is a request parser plus a two-pass composer over the existing batch and capture runners. No new floor tier, no `.ngb` format change. I1-I6 hold.

## The ceiling, stated up front

Involution is necessary, not sufficient. A function can be an involution and still be the wrong function. The `IMPOSTER_BSWAP` arm swaps only the outer byte pair: it round-trips, so the relation accepts it, yet it is not a byte swap. The gate asserts this acceptance so the ceiling is a tested fact, not a footnote. Separating the imposter needs a value oracle, which is exactly what G9-G23 provide. Metamorphic relations and value oracles are complementary floors, not substitutes.

## Why not count relations

A metric that rewards the number of relations is a rat farm (Goodhart). An agent stuffs tautologies to inflate the count. The unit that matters is verification power: does the relation reject a wrong program from an adversarial distribution. G24 measures power directly, the rotl8 arm is a wrong program the relation rejects with a witness, and the imposter arm is the bound on that power.

## Robustness

Reused from G23. The batch runner emits one crash-safe line per probe. Any candidate witness is confirmed by an isolated clean re-run, so a reject requires a reproducible violation. A two-pass design keeps the sweep in two backend sessions, not two per probe.

## What we are not building

- No `.ngb` format change.
- No language front end. The request is hand-authored; candidate identification is a parked follow-on.
- No relation beyond involution yet. Round-trip, idempotent, and commutative are named branches in the verifier's dispatch, unimplemented.
- No claim that the relation proves correctness.

## Design

- `fixtures/metamorphic/bswap32.c`: real, `EVIL_BSWAP` (rotl8), `IMPOSTER_BSWAP` (outer-swap).
- `fixtures/metamorphic/bswap32.req`: `relation=involution entry=argv domain=u32 eq=exact`.
- `scripts/mint-metamorphic-fixtures.sh`: pinned `gcc:13`, three committed `.ngb`, distinct hashes.
- `scripts/agent-eval/metamorphic-verify.sh`: parse request, sweep the domain, compose `f(f(x))`, witness on violation, isolated confirm.
- `scripts/check-metamorphic-involution.sh`: honest accepts, rotl8 rejects with witness `x=1`, imposter accepts (ceiling).

## Known limit

The domain is a bounded deterministic sweep (powers of two, edge bytes, mixed constants). A violation whose only trigger sits outside the sweep would pass, the same budget dial as G23. The ceiling above is the deeper limit: the relation cannot separate two functions that share it.

## Kill trigger

If a useful relation cannot be checked without computing the expected value, it is a value oracle in disguise; route it to the G9 floor instead of growing this one.
