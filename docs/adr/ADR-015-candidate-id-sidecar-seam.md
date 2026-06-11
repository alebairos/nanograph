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
| H3 agent-loop latency | **PROVEN** (follow-on) | Novel codec + 5/5 mined under house-style prose; variant A fail-closed without relation keyword; see follow-on doc |
| H4 boundary independence | **PROVEN** | Sidecar lives in `spike/candidate-id/` only |

**Decision:** **skill-only.** Publish `propose-req.py` and holdout script as an external agent skill. Do not merge sidecar into `tools/` or gated CI. Do not open G63–G64 until product verdict moves to **adopt sidecar** (H3 recall alone is insufficient; prose dependency and shared-authorship confound remain).

## Addendum 2026-06-11 (#85–#87): H3 follow-on tranches

H3 moved from inconclusive to **PROVEN** under a pre-registered protocol with frozen sidecar (`FROZEN.sha256` unchanged across tranches).

| Tranche | Evidence |
| --- | --- |
| 1 (#72) | Novel `h3_nibbles`; verdict-equivalent reject; authoring ≤1000 ms |
| 2 (#85) | Mined go-base64; variant A REFUTED (no relation prose → fail closed); variant B byte-exact recall |
| 3 (#87) | Four remaining mined scorecards; 4/4 PROVEN; value_oracle branch in spike verifier |

**Verdict unchanged:** skill-only. The sidecar is a **convention lint** (regex over house-style headers). It does not understand codecs. G63–G64 stay parked.

**Separate from G73:** sidecar authors `.req`; probe generator (ADR-020) authors inputs. Witness production ≠ detection.

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
