---
name: milestone-gate
description: Run the correct verification for each NanoGraph milestone (M0–M7) and product proof steps.
---

# Milestone gate

Canonical definitions: [`docs/specs/MILESTONES.md`](../../docs/specs/MILESTONES.md)

## Commands

| When | Run |
| --- | --- |
| Every session | `./scripts/harness-session-start.sh` |
| Before merge | `./scripts/check-canonical-drift.sh` |
| Full matrix | `./scripts/check-all-proofs.sh` |

## Per milestone minimum

| Milestone | Must pass |
| --- | --- |
| M0 | Session script + drift check |
| M1 | `./scripts/check-hello-proof.sh` P1 |
| M2 | `check-hello-proof.sh` P1–P3; `check-ngb-roundtrip.sh` |
| M3 | `check-hello-proof.sh` P1–P4; `check-probe-audit-log.sh` |
| M4 | `check-add-two-proof.sh` |
| M5 | `check-add-two-patched-proof.sh`; `check-probe-diff.sh` |
| M6 | `check-probe-disassemble.sh` |
| M7 | `check-print-42-proof.sh` |
| Product proof close | `check-all-proofs.sh` + step-specific scripts |

Do not duplicate full gate tables in PRs. Link the milestone section in `MILESTONES.md`.
