# Nano goals (decided)

Ordered goals for NanoGraph v3. Each canonical program gets the same proof ladder (static → structural → behavioral → audit).

## Claims ledger (2026-06-05)

What the program has settled versus what still needs a goal.

| Claim | Status | Evidence |
| --- | --- | --- |
| Integrity gating beats raw ELF at author time | **Proven** | 3/3 hand-picked bad edits; 1000/1000 fuzz (ADR-001) |
| Two-agent message interchange works | **Proven** | G8 scripted loop, 2 rounds, CI-gated |
| Oracle is computed, not looked up | **Proven** | G9 `conf-eval`, G11 `yield=stdout` in loop |
| Static micro-op rejects structural mistakes | **Proven** | G10 `not_rodata`, G12 `value_mismatch`, CI-gated |
| Miscompilation caught by conformance floor | **Proven** | G9 `add_two_patched` negative (exit 3 vs spec 2) |
| Live Cursor CLI author completes the loop | **Proven** | G13 first run, 1 round, `composer-2.5` |
| Static gate rejects operational errors pre-execution | **Proven** | Operational-error matrix: 4/4 bad classes rejected at 0 executions (`--expect-off` + `--expect-new`); gated in `check-all-proofs.sh` |
| Stacked gates reduce live-agent retries | **Not the claim** | G14 blind A/B was inconclusive (answer leaked across ~18 repo files, no tool-call trace); reframed to pre-execution rejection above |
| Live eval generalizes beyond print_42 | **Parked** | Single program only; no reason to expand until a workload needs it |
| Human-auditable verdict trail | **Parked** | `probe_bundle` is text concatenation; revisit if an external auditor needs it |

ADR-001 re-open trigger *"A live-agent eval shows NanoGraph's typed errors cut real retry counts"* was tested by G14 and **not met**. `composer-2.5` made no errors on the blind single-byte task, so there were no retries to cut. Retry-reduction positioning is dropped. The product claim rests on integrity (1000/1000 fuzz) and execution-grounded conformance (G9).

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

## Completed (post-P20 ladder)

| ID | Goal | Issue | Status |
| --- | --- | --- | --- |
| G8 | Deterministic two-agent author/auditor loop | #30 | Done |
| G9 | Ground-truth conformance floor (compute expected from spec) | #31 | Done |
| G10 | Micro-op static floor (`RODATA_BYTE_WRITE`) | #32 | Done |
| G11 | Computed oracle for the two-agent loop (`yield=stdout`) | #33 | Done |
| G12 | Value-bound micro-op (`--expect-new` derived digit) | #34 | Done |
| G13 | Live-agent harness + first run (Cursor CLI author) | #35 | Done |
| G14 | Blind live falsification of retry-reduction claim | #35 | Done (inconclusive; claim reframed) |
| G15 | Operational-error matrix (deterministic gate coverage) | #35 | Done (4/4 pre-exec) |
| G16 | Isolated author sandbox for live-agent eval | #36 | Done |

G8 spec: [`TWO-AGENT-PROBE-PROTOCOL.md`](TWO-AGENT-PROBE-PROTOCOL.md). Harness `scripts/agent-eval/run-two-agent-loop.sh`, gated by `scripts/check-two-agent-loop.sh`.

G9 spec: [`CONFORMANCE-FLOOR.md`](CONFORMANCE-FLOOR.md), decision [`../adr/ADR-002-ground-truth-conformance.md`](../adr/ADR-002-ground-truth-conformance.md). Harness `scripts/agent-eval/conformance-check.sh`, gated by `scripts/check-conformance-floor.sh`.

G10 spec: [`MICROOP-FLOOR.md`](MICROOP-FLOOR.md). Harness `tools/bin/ngb-microop`, gated by `scripts/check-microop-floor.sh`.

G13/G14 spec: [`LIVE-AGENT-EVAL.md`](LIVE-AGENT-EVAL.md). Harness `scripts/agent-eval/run-live-agent-loop.sh`, opt-in. Skill `.cursor/skills/live-ngb-author/SKILL.md`. G13 leaked the answer in the skill; G14 removed the leak and ran blind A/B. Both arms 1 round / 1 exec, retry-reduction trigger not met. Logs: `.harness-data/agent-eval/live-agent/run-g14-{stacked,auditor-only}.jsonl`.

G16 spec: [`AUTHOR-SANDBOX.md`](AUTHOR-SANDBOX.md), decision [`../adr/ADR-003-author-sandbox.md`](../adr/ADR-003-author-sandbox.md). Harness `prepare-author-sandbox.sh`, `audit-author-isolation.sh`, gated by `scripts/check-author-sandbox.sh`. Live loop uses `--workspace $SANDBOX` only; streams persisted under `.harness-data/agent-eval/live-agent/`.

## Next goals

The retry-reduction line is closed (G14). G16 closes the repo-leakage gap for live eval. No further goals are committed. The proven claim is integrity plus execution-grounded conformance, and it stands on the deterministic suite without a live-agent number.

Parked ideas, each needing a concrete reason before it earns a slot. Do not build speculatively.

| Parked | Trigger to revive |
| --- | --- |
| Second program live eval (`add_two` exit-code) | A real task needs a non-print_42 patch verified live |
| Runtime operands in ConfSpec | An intent must reference execution inputs, not constants |
| Multi-op micro-op set | A real edit shape beyond single-byte rodata appears |
| Differential conformance (one binary, two specs) | A spec-collision risk shows up in practice |
| Portable verdict bundle (JSON) | An external auditor needs to verify without re-running probes |
| Zerolang MIR seam (spike) | An external intent source wants to feed the conformance floor |

## Completed product proof

**Product proof P01–P20** decided Continue scoped to verifiable editing (ADR-001).

Spec: [`PRODUCT-PROOF.md`](PRODUCT-PROOF.md)

## Explicitly not in scope

- NanoLang syntax or compiler
- Cycle-accurate `probe verify` / gem5
- Multi-arch
- v2 JSON audit manifest inside `.ngb`
- Live eval in CI (requires `CURSOR_API_KEY`, nondeterministic)

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
| #35 | G13 live harness, G14 blind falsification, G15 operational-error matrix |
| #36 | G16 isolated author sandbox |
