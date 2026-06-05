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
| G9 | Ground-truth conformance floor (compute expected from spec) | #31 | Done |
| G10 | Micro-op static floor (`RODATA_BYTE_WRITE`) | #32 | Done |
| G11 | Computed oracle for the two-agent loop (`yield=stdout`) | #33 | Done |
| G12 | Value-bound micro-op (`--expect-new` derived digit) | #34 | Done |
| G13 | Live-agent eval (Cursor CLI author vs stacked gates) | #35 | Spec |

G8 spec: [`TWO-AGENT-PROBE-PROTOCOL.md`](TWO-AGENT-PROBE-PROTOCOL.md). Harness `scripts/agent-eval/run-two-agent-loop.sh`, gated by `scripts/check-two-agent-loop.sh`.

G9 spec: [`CONFORMANCE-FLOOR.md`](CONFORMANCE-FLOOR.md), decision [`../adr/ADR-002-ground-truth-conformance.md`](../adr/ADR-002-ground-truth-conformance.md). Harness `scripts/agent-eval/conformance-check.sh`, gated by `scripts/check-conformance-floor.sh`.

G10 spec: [`MICROOP-FLOOR.md`](MICROOP-FLOOR.md). Harness `tools/bin/ngb-microop`, gated by `scripts/check-microop-floor.sh`.

G13 spec: [`LIVE-AGENT-EVAL.md`](LIVE-AGENT-EVAL.md). Harness `scripts/agent-eval/run-live-agent-loop.sh`, opt-in (not CI-gated). Skill `.cursor/skills/live-ngb-author/SKILL.md`.

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
| #31 | G9 conformance floor |
| #32 | G10 micro-op floor |
| #33 | G11 computed oracle |
| #34 | G12 value-bound micro-op |
| #35 | G13 live-agent eval |
