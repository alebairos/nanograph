# Nano goals (decided)

Ordered goals for NanoGraph v3. Each canonical program gets the same proof ladder (static → structural → behavioral → audit).

## Completed (M0–M7)

| ID | Goal | Milestone | Status |
| --- | --- | --- | --- |
| G1 | Hello pack/parse + run | M2 | Done (#3) |
| G2 | Hello audit-log | M3 | Done (#4) |
| G3 | add_two genesis | M4 | Done (#5) |
| G4 | probe disassemble | M6 | Done (#7) |
| G5 | Signed graph patch | M5 | Done (#6) |
| G6 | probe diff | M5 | Done (#6) |
| G7 | print_42 stdout | M7 | Done (#8) |

## Active program (post-P20)

| ID | Goal | Issue | Status |
| --- | --- | --- | --- |
| G8 | Deterministic two-agent author/auditor loop | #30 | Done |

Spec: [`TWO-AGENT-PROBE-PROTOCOL.md`](TWO-AGENT-PROBE-PROTOCOL.md)

Harness: `scripts/agent-eval/run-two-agent-loop.sh`, gated by `scripts/check-two-agent-loop.sh`.

## Completed product proof

**Product proof P01–P20** decided Continue scoped to verifiable editing (ADR-001).

Spec: [`PRODUCT-PROOF.md`](PRODUCT-PROOF.md)

## Explicitly not in P01–P20

- NanoLang syntax or compiler
- Cycle-accurate `probe verify` / gem5
- Multi-arch
- v2 JSON audit manifest inside `.ngb`

## Issue mapping

| Range | Binds |
| --- | --- |
| #3–#8 | G1–G7 technical milestones |
| #9–#28 | P01–P20 product proof |
| #30 | G8 two-agent loop |
