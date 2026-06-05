# Product proof program (P01–P20)

Formal program to answer one question by step P20.

**Is NanoGraph v3 a real agent-native artifact, or an elaborate frozen-fixture demo?**

## What we have already (M0–M7, G1–G7)

| Capability | Status |
| --- | --- |
| `.ngb` v0 pack/parse with I1–I6 | Shipped |
| Canonical programs hello, add_two, print_42 | Shipped |
| Patch + diff on add_two | Shipped |
| NanoProbe audit-log, diff, disassemble | Shipped |
| Bash proof ladder + CI | Shipped |
| Agent-facing patch CLI | **Not shipped** |
| Agent eval vs baseline | **Not shipped** |
| Product verdict | **Not written** |

Technical milestones proved the **format and human audit path**. This program proves the **agent loop**.

## Falsification criteria (decide at P20)

**Continue** (NanoGraph earns next investment) when all hold:

1. An agent completes Task A (add_two exit 4) using `ngb-patch` + validation feedback in ≤5 tool iterations without reading golden patch bytes.
2. Task A with `.ngb` beats raw ELF hex-edit baseline on success rate or iteration count (documented in P16 metrics).
3. `./scripts/check-all-proofs.sh` stays green through P19.
4. Invalid patches are rejected with structured I1–I6 errors (P10–P11 suites).

**Pivot** when:

- Agents succeed on ELF but fail on `.ngb` consistently → graph adds friction; narrow scope to human-only probe toolkit.
- Patch chain works only for hand-authored deltas → redesign agent patch surface before more programs.

**Kill** when:

- Both agent tasks fail after bounded harness effort and ELF baseline also fails → problem is task/harness, not format.
- Invalid patches pass validation → trust boundary broken; stop until NGB version bump.

## Proof ladder (unchanged per program)

Every new canonical graph uses P1–P4:

| Layer | Checks |
| --- | --- |
| P1 static | Hash, byte sizes, fixture rebuild |
| P2 structural | parse/roundtrip |
| P3 behavioral | run ELF (exit and/or stdout) |
| P4 audit | `nano-probe audit-log` golden |

## Program steps

| Step | Issue | Deliverable | Verification |
| --- | --- | --- | --- |
| P01 | #9 | Docs/harness sync (M5–M7 in MILESTONES, milestone-gate, NANO-GOALS) | drift + manual review |
| P02 | #10 | This spec linked from `docs/CANONICAL.md` | drift check |
| P03 | #11 | `check-all-proofs.sh` runs full CI proof matrix locally | script exits 0 |
| P04 | #12 | `ngb-patch` CLI applies delta, validates, prints root hash | integration test script |
| P05 | #13 | `ngb-parse --json` emits invariant id on failure | golden stderr JSON |
| P06 | #14 | `nano-probe trace` replays patch chain | golden stdout + CI |
| P07 | #15 | Agent patch skill (`ngb-agent-patch`) | skill + example invocation |
| P08 | #16 | print_42 patched → `43\n` | `check-print-42-patched-proof.sh` |
| P09 | #17 | add_two 2-patch chain (exit 2→3→4) | patched proof + I6 |
| P10 | #18 | `check-patch-reject.sh` invalid delta suite | script exits 0 |
| P11 | #19 | Wrong precondition hash rejected | cases in reject suite |
| P12 | #20 | Agent eval harness (`scripts/agent-eval/`) | skeleton runs |
| P13 | #21 | Task A spec + success rubric (add_two→exit 4) | documented in eval/ |
| P14 | #22 | Task B spec (print_42→43) | documented in eval/ |
| P15 | #23 | ELF hex baseline tasks (same goals) | documented in eval/ |
| P16 | #24 | Metrics comparison doc | table with evidence |
| P17 | #25 | `nanograph-adversary` agent | harness doc |
| P18 | #26 | C API integration doc (`docs/specs/NGB-C-API.md`) | review checklist |
| P19 | #27 | Loop driver product-proof queue | loop_state binds Pxx |
| P20 | #28 | ADR product verdict | `docs/adr/ADR-001-product-verdict.md` |

## Execution rules

1. One open product-proof issue at a time (same as M0–M7).
2. Bind `loop_state.json` to current P step.
3. Scripts before prose. Goldens before features.
4. P12–P16 may run evals without a new canonical program.
5. P20 requires P13–P16 evidence. No verdict without metrics.

## Agent intuition (hypothesis under test)

Agents need a **validated byte graph** with **precondition-gated patches** and **deterministic audit probes** more than they need another syntax. NanoGraph is the artifact; NanoProbe is the human/agent shared verifier.

If the hypothesis is wrong, ELF + objdump + git diff is enough and NanoGraph should remain a research repo.

## Issue labels

| Label | Meaning |
| --- | --- |
| `milestone:p01` … `milestone:p20` | Product proof step |
| `type:product-proof` | Part of this program |
| `meta:product-program` | Tracking label on all P01–P20 issues |
