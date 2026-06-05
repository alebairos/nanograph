# Milestones (NanoGraph)

Bind agent work to **one milestone** at a time. Do not mix M2 packer work with M4 sim scope.

| Milestone | Goal | Done when |
| --- | --- | --- |
| **M0** | Concept anchored | `nanograph.md` present; v3 stance agreed; harness wired |
| **M1** | `.ngb` v0 spec frozen | [`NGB-V0.md`](NGB-V0.md) + hex fixture under `fixtures/` |
| **M2** | Reference pack + parse | `tools/ngb-pack`, `tools/ngb-parse`, golden roundtrip CI |
| **M3** | First probe | `tools/nano-probe audit-log` deterministic stdout vs golden |
| **M4** | Optional depth | `probe diff`, then `disassemble`; sim only with explicit ADR |

## Per-milestone verification

| Milestone | Minimum verify |
| --- | --- |
| M0 | `./scripts/harness-session-start.sh`; `./scripts/check-canonical-drift.sh` |
| M1 | Drift check; human review of `NGB-V0.md` + fixture |
| M2 | `./scripts/check-ngb-roundtrip.sh` (added with M2) |
| M3 | `./scripts/check-probe-audit-log.sh` (added with M3) |
| M4 | Per skill in milestone-gate when tools land |

## Out of scope until M4+

- `nano graph patch` CLI
- Cycle-accurate `probe verify`
- Multi-arch
- Merkle edge DAG beyond node content hashes
