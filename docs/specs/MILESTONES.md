# Milestones (NanoGraph)

Bind agent work to **one milestone** at a time. Technical milestones **M0–M7** delivered G1–G7. Product proof **P01–P20** is active after M7.

| Milestone | Goal | Done when |
| --- | --- | --- |
| **M0** | Concept anchored | `nanograph.md` present; v3 stance agreed; harness wired |
| **M1** | Canonical hello **P1 static** | [`HELLO-CANONICAL.md`](HELLO-CANONICAL.md) + `fixtures/hello.ngb` + `check-hello-proof.sh` P1 |
| **M2** | Hello **P2 structural** + **P3 behavioral** | `ngb-pack`/`ngb-parse` reproduce golden; roundtrip; ELF runs (CI/linux) |
| **M3** | Hello **P4 audit** | `nano-probe audit-log` vs golden stdout |
| **M4** | Canonical **add_two** (1+1 → exit 2) | [`CANONICAL-ADD-TWO.md`](CANONICAL-ADD-TWO.md) + `check-add-two-proof.sh` |
| **M5** | Patch + diff | `add_two_patched.ngb` + `check-add-two-patched-proof.sh` + `check-probe-diff.sh` |
| **M6** | probe disassemble | `check-probe-disassemble.sh` on hello + add_two |
| **M7** | print_42 stdout | `check-print-42-proof.sh` P1–P4 |

See [`NANO-GOALS.md`](NANO-GOALS.md) for G1–G7. See [`PRODUCT-PROOF.md`](PRODUCT-PROOF.md) for P01–P20.

## Per-milestone verification

| Milestone | Minimum verify |
| --- | --- |
| M0 | `./scripts/harness-session-start.sh`; `./scripts/check-canonical-drift.sh` |
| M1 | `./scripts/check-hello-proof.sh` (P1); drift check |
| M2 | `check-hello-proof.sh` (P1–P3); `check-ngb-roundtrip.sh` |
| M3 | `check-hello-proof.sh` (P1–P4); `check-probe-audit-log.sh` |
| M4 | `check-add-two-proof.sh` |
| M5 | `check-add-two-patched-proof.sh`; `check-probe-diff.sh` |
| M6 | `check-probe-disassemble.sh` |
| M7 | `check-print-42-proof.sh` |
| **All shipped** | `./scripts/check-all-proofs.sh` |

Regenerate canonical bytes with `tools/bin/*-fixture` only when `NGB-V0.md` layout changes.

## Out of scope until product proof lands

- Cycle-accurate `probe verify` / gem5
- Multi-arch hello variants
- Merkle edge DAG beyond node content hashes
