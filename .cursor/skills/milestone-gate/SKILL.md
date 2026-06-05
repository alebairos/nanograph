---
name: milestone-gate
description: Run the correct verification for each NanoGraph milestone (M0–M4). Use when closing a milestone or before PR.
---

# Milestone gate

Canonical definitions: [`docs/specs/MILESTONES.md`](../../docs/specs/MILESTONES.md)

## Commands

| When | Run |
| --- | --- |
| Every session | `./scripts/harness-session-start.sh` |
| Before merge | `./scripts/check-canonical-drift.sh` |
| M2+ format tools | `./scripts/check-ngb-roundtrip.sh` (when present) |
| M3+ probe | `./scripts/check-probe-audit-log.sh` (when present) |

## Per milestone minimum

| Milestone | Must pass |
| --- | --- |
| M0 | Session script + drift check; harness files present |
| M1 | `./scripts/check-hello-proof.sh` P1; drift check |
| M2 | `check-hello-proof.sh` P1–P3; `check-ngb-roundtrip.sh` |
| M3 | `check-hello-proof.sh` P1–P4; `check-probe-audit-log.sh` |
| M4 | Per ADR; no sim without explicit scope |

Do not duplicate full gate tables in PRs. Link the milestone section in `MILESTONES.md`.
