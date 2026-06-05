# Canonical documentation (anti-drift)

**Do not fork the NanoLang v3 story into multiple competing specs.** One concept narrative, one format spec, one milestone plan.

| Document | Canonical path | Role |
| --- | --- | --- |
| **Concept / philosophy** | [`nanograph.md`](../nanograph.md) | Zerolang contrast, v3 stance (raw `.ngb`, NanoProbe post-hoc) |
| **`.ngb` v0 byte layout** | [`docs/specs/NGB-V0.md`](specs/NGB-V0.md) | Executable spec for container (offsets, hashes, invariants) |
| **Canonical hello** | [`docs/specs/HELLO-CANONICAL.md`](specs/HELLO-CANONICAL.md) | P1–P4 proof ladder for the first sound artifact |
| **Nano goals** | [`docs/specs/NANO-GOALS.md`](specs/NANO-GOALS.md) | G1–G7 complete; product proof queue |
| **Product proof** | [`docs/specs/PRODUCT-PROOF.md`](specs/PRODUCT-PROOF.md) | P01–P20 agent-native falsification program |
| **Canonical add_two** | [`docs/specs/CANONICAL-ADD-TWO.md`](specs/CANONICAL-ADD-TWO.md) | Second program (M4), 1+1 via exit code 2 |
| **Milestones** | [`docs/specs/MILESTONES.md`](specs/MILESTONES.md) | M0–M7 technical gates; P01–P20 product proof |
| **Implementation map** | [`docs/specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md) | Layer → path in this repo |
| **Agent harness** | [`docs/specs/AGENT-HARNESS.md`](specs/AGENT-HARNESS.md) | How agents run work here |
| **Issue labels** | [`docs/specs/ISSUE-LABELS.md`](specs/ISSUE-LABELS.md) | GitHub label taxonomy |

## Change protocol

1. Philosophy or agent/human contract change → edit `nanograph.md` first, then align `NGB-V0.md` / milestones if needed.
2. Byte layout or patch-chain semantics → edit `NGB-V0.md` first, then tools.
3. Tooling paths, scripts, harness layout → edit `ARCHITECTURE.md` in this repo.
4. Run `./scripts/check-canonical-drift.sh` before merge when tools exist.

## Drift checks

| Forbidden | Allowed instead |
| --- | --- |
| Second full v3 essay under `docs/` | Link `nanograph.md` |
| Embedded JSON audit manifest in `.ngb` (v2) | v3 patch log only; see `NGB-V0.md` |
| Duplicating milestone gates in PR prose only | Link `MILESTONES.md` section |
