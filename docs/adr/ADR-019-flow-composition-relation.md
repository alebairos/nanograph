# ADR-019 — flow_composition metamorphic relation

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G69

## Context

Iterated CA evolution satisfies `flow(m+n,s) == flow(n, flow(m,s))`. Incremental hash/codec APIs that disagree with one-shot computation share the same shape. `round_trip` checks one cycle, not state threading across calls.

## Decision

Add relation **`flow_composition`** to the metamorphic verifier. For probe triples `(n,m,seed)` with `n+m <= max_total`, require `flow(n+m,seed) == flow(m, flow(n,seed))`. Reject witnesses name `n`, `m`, `seed`, `once`, `composed`, `hex=`.

G69 ships a modeled specimen: `fixtures/metamorphic/ca_flow.c` with `EVIL_SKIP` omitting one middle generation when `steps >= 2`.

## Why the adjacent lower layer is insufficient

No existing relation compares one-shot multi-step output to composed partial runs.

## What we are not building

- No streaming API with hidden state beyond argv seed (state is the printed u32).
- No `.ngb` format change.

## Demonstrated power versus implemented checks

G69 demonstrates rejection on pre-registered `(n,m,seed)` triple. No broader composition power claim until a second mined incremental-update bug exercises the branch.

## Kill trigger

If every catch is a single-step bug already caught by `round_trip` or `linear_xor`, route there instead.
