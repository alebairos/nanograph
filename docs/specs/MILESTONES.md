# Milestones (NanoGraph)

Bind agent work to **one milestone** at a time. **M1–M3** collectively deliver the [canonical hello](HELLO-CANONICAL.md) proof ladder.

| Milestone | Goal | Done when |
| --- | --- | --- |
| **M0** | Concept anchored | `nanograph.md` present; v3 stance agreed; harness wired |
| **M1** | Canonical hello **P1 static** | [`HELLO-CANONICAL.md`](HELLO-CANONICAL.md) + `fixtures/hello.ngb` + `check-hello-proof.sh` P1 |
| **M2** | Hello **P2 structural** + **P3 behavioral** | `ngb-pack`/`ngb-parse` reproduce golden; roundtrip; ELF runs (CI/linux) |
| **M3** | Hello **P4 audit** | `nano-probe audit-log` vs golden stdout |
| **M4** | Canonical **add_two** (1+1 → exit 2) | Second program + P1–P3; see [`CANONICAL-ADD-TWO.md`](CANONICAL-ADD-TWO.md) |
| **M5** | Patch + diff | One signed patch on add_two; `probe diff` |
| **M6** | Optional depth | `disassemble`; print_42 or sim only with ADR |

See [`NANO-GOALS.md`](NANO-GOALS.md) for full goal ordering (G1–G7).

## Per-milestone verification

| Milestone | Minimum verify |
| --- | --- |
| M0 | `./scripts/harness-session-start.sh`; `./scripts/check-canonical-drift.sh` |
| M1 | `./scripts/check-hello-proof.sh` (P1); drift check |
| M2 | `./scripts/check-hello-proof.sh` (P1–P3); `./scripts/check-ngb-roundtrip.sh` |
| M3 | `./scripts/check-hello-proof.sh` (P1–P4); `./scripts/check-probe-audit-log.sh` |
| M4 | Per milestone-gate when tools land |

Regenerate canonical bytes with `tools/bin/hello-fixture` only when `NGB-V0.md` layout changes.

## Out of scope until M4+

- `nano graph patch` CLI
- Cycle-accurate `probe verify`
- Multi-arch hello variants
- Merkle edge DAG beyond node content hashes
- `"Hello, world\\n"` string in the ELF (exit-only canonical)
