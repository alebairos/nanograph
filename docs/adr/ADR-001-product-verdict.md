# ADR-001 — NanoGraph product verdict

**Status:** Accepted (Continue with measured evals)  
**Date:** 2026-06-05  
**Program:** P01–P20 product proof

## Context

NanoGraph v3 tests whether agent-first `.ngb` graphs with post-hoc NanoProbe tooling beat raw ELF editing for bounded patch tasks. Technical milestones M0–M7 and product-proof infrastructure P01–P19 are shipped with green `check-all-proofs.sh`.

## Decision

**Continue** investing in agent-native byte graphs and probe-gated patches.

## Evidence

| Falsification criterion | Result |
| --- | --- |
| Agent Task A ≤5 iterations | **Pending** — harness + tasks shipped; no live eval log yet |
| `.ngb` beats ELF baseline | **Pending** — metrics table placeholders in `AGENT-EVAL-METRICS.md` |
| Proofs green through P19 | **Met** — unified proof runner includes chain, reject, trace, patch CLI |
| Invalid patches rejected | **Met** — `check-patch-reject.sh` + I6 chain on `add_two_chain.ngb` |

## Fixes discovered in program

1. `ngb_apply_patch` must append after existing patch log, not overwrite at `patch_off`.
2. I6 precondition check must hash prior patch log bytes, not image-only state.

## Next investment

1. Run Task A and Task B evals; fill metrics table.
2. Optional `nanograph-adversary` on eval PRs.
3. Third canonical program only after agent converges on Task A without golden leakage.

## Pivot triggers

- Task A live eval needs >5 iterations in majority of runs.
- ELF baseline wins on both tasks with lower tool-call count.
- New invariant class appears that scripts do not catch.

## Kill triggers

- Agents cannot use invariant JSON without reading fixture source.
- Patch surface grows faster than proof coverage.
