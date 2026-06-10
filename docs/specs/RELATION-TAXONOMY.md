# Relation taxonomy (G66)

Predictive families for metamorphic relations and formal mining signals. The runnable catalog lives in [`METAMORPHIC-RELATIONS.md`](METAMORPHIC-RELATIONS.md). Mining stage-2 signals live in [`../BACKTEST.md`](../BACKTEST.md).

Decision: [`../adr/ADR-016-relation-taxonomy.md`](../adr/ADR-016-relation-taxonomy.md).

## Why families

Relations grew one bug at a time. Families name the algebraic shape so mining can ask "does this fix restore X?" before inventing a new branch. Power is measured per family with a demonstrated witness, not by branch count (ADR-007 anti-Goodhart).

## Families

| Family | Property shape | Relations in catalog | Mining signal (fix commit / test diff) |
| --- | --- | --- | --- |
| Identity | `f∘f = id`, `f∘f = f` | `involution`, `idempotent` (named) | "inverse", "idempotent", self-inverse API |
| Order | axioms, monotone maps | `cmp_order`, `size_monotone` | comparator contract, overflow inverts order, sort stability |
| Section / retraction | `encode∘decode = id` on accepted inputs | `round_trip` | non-minimal acceptance, invalid skip, truncation |
| Invariant preservation | scalar statistic conserved by `f` | `conserve_popcount` | permutation/conservation, particle count |
| Homomorphism | `f(a⊕b) = f(a)⊕f(b)` | `linear_xor` | CRC combine, GF(2) fold, linear CA step |
| Flow / composition | `f^(m+n) = f^m ∘ f^n` | `flow_composition` | incremental hash/codec disagreeing with one-shot |
| Image / coverage | reachability, containment | `range_coverage` | off-by-one span, endpoint never reached |
| Point oracle | `f(s) == expected` (probe table) | `value_oracle` | named input/output regression, not self-oracling |

`value_oracle` uses the same `.req` seam but is a **point-oracle probe table**, not a metamorphic relation. It complements relations when the bug is an acceptance gap (`encode∘decode` is identity but validation is wrong).

## Floor handoff (unchanged)

Cheap relation first, expensive oracle when the relation ceiling leaves imposters. See ADR-008. Homomorphism and flow families share the same ceiling pattern as involution (necessary, not sufficient).

## Computational irreducibility (oracle hardness)

When the expected output is as hard to compute as the function (rule 30 golden, no closed form), only execution-grounded diff or a weaker invariant applies. When a closed-form invariant exists (rule 90 popcount row, linear XOR step), a relation can be the oracle. The case-fit rubric `oracle_hardness=2` row is this dichotomy operationalized.

## Using the taxonomy in mining

Stage 2 (signal) in [`../BACKTEST.md`](../BACKTEST.md) adds a family checklist. Score the candidate against an existing relation before proposing a new branch. A new branch needs a modeled or mined witness and an ADR kill trigger.
