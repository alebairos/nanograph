# ADR-015 — candidate-ID sidecar at the VerificationRequest seam

**Status:** Accepted (spike verdict)
**Date:** 2026-06-11
**Goal:** G55 (#72)

## Context

ADR-007 placed a language-aware identification seam outside the blind verify floor. Hand-authored `.req` files scale poorly for agent loops.

## Spike verdict (G55)

| Hypothesis | Result | Product implication |
| --- | --- | --- |
| H1 recall ≥4/5 | **PROVEN** (4/5) | Heuristics on freestanding C comments recover most codec `.req` shapes |
| H2 verdict equivalence | **PROVEN** | Auto `.req` does not break the floor when fields match |
| H3 agent-loop latency | **INCONCLUSIVE** | No novel-codec timing evidence |
| H4 boundary independence | **PROVEN** | Sidecar lives in `spike/candidate-id/` only |

**Decision:** **skill-only.** Publish `propose-req.py` and holdout script as an external agent skill. Do not merge sidecar into `tools/` or gated CI. Do not open G63–G64 until H3 passes on a novel edit.

## Boundary (unchanged)

```
[language-aware sidecar]  --writes-->  VerificationRequest (.req)
[build/mint harness]      --writes-->  candidate.ngb
[nanograph floor]         --reads-->  .req + .ngb only
```

## What we are not building

- No AST front end in the verifier.
- No zerolang/MIR ingestion.
- No new relation types.

## Kill trigger

If a second spike on novel code shows sidecar `.req` diverges from hand `.req` on verdict, revert to hand-only and close G63–G64.
