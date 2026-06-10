# ADR-018 — rule 184 conserve_popcount bridge (G68)

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G68

## Context

G50 `conserve_popcount` on `reverse32` overlaps `involution` on the same mutant (ADR-013 kill trigger). Rule 184 (particle traffic CA) conserves popcount per generation but is not an involution. The CA conformance lane (stdout golden) and scalar relation lane were disjoint.

## Decision

Ship rule **184** one-step specimen (`ca_step.c` with `-DRULE=184`) verified by existing **`conserve_popcount`** relation. `EVIL_DROP` clears bit 0 when set, breaking conservation with a witness `linear_xor` and `involution` do not target.

Mark rule 184 **Done** in the ruliad exploration ledger (NANO-GOALS). No new relation branch.

## Why the adjacent lower layer is insufficient

Full-grid CA conformance (G17) diffs stdout. A single-step conservation check is cheaper and ties the scalar relation catalog to Wolfram particle conservation without minting a 9 KB golden.

## What we are not building

- No claim that row popcount conservation implies correct rule 184 dynamics globally.
- No `.ngb` format change.

## Kill trigger

If `conserve_popcount` on rule 184 never rejects a mutant that CA golden diff also catches with equal witness cost, prefer golden-only for 184.
