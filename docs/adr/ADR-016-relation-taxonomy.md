# ADR-016 — Relation taxonomy for mining and catalog growth

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G66

## Context

Metamorphic relations were added reactively (one branch per mined bug). Wolfram-style structure (linear CA rules, particle conservation, iterated flow) suggested missing families: homomorphism and composition. Without a taxonomy, mining greps fix messages ad hoc and every catch risks a one-off branch.

## Decision

Add [`docs/specs/RELATION-TAXONOMY.md`](../specs/RELATION-TAXONOMY.md) as the predictive family index. Extend [`METAMORPHIC-RELATIONS.md`](../specs/METAMORPHIC-RELATIONS.md) with a family column. Extend [`BACKTEST.md`](../BACKTEST.md) stage 2 with a per-family signal checklist. Label `value_oracle` explicitly as a point-oracle probe table, not a metamorphic relation.

## Why the adjacent lower layer is insufficient

The relation table in METAMORPHIC-RELATIONS.md lists implementations only. Mining and goal selection need the shape (homomorphism, flow) without reading every ADR.

## What we are not building

- No new verifier code in G66. Docs only.
- No claim that every bug maps to one family. Overlap is expected; the taxonomy ranks which family to try first.

## Kill trigger

If the checklist never changes mining outcomes versus ad hoc grep after three mining passes, fold it into CASE-FIT-RUBRIC only and drop the standalone doc.
