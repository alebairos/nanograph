---
name: ngb-boundary-gate
description: >-
  Check .ngb v0 boundary invariants (I1–I6) before accepting pack/parse/probe
  changes. Use when editing NGB-V0.md or tools/**.
---

# NGB boundary gate

Spec: [`docs/specs/NGB-V0.md`](../../docs/specs/NGB-V0.md)

## Before coding

- State which invariants apply to the change.
- If layout changes, bump `version_u16` and document migration in `NGB-V0.md`.

## Invariants

| ID | One-line check |
| --- | --- |
| I1 | Magic `NGB\0` and known version |
| I2 | Section offsets and lengths within file |
| I3 | Node ranges ⊆ image |
| I4 | Node content_hash matches slice |
| I5 | Unique node_id |
| I6 | Patch precondition chain |

## After coding

- Roundtrip or parse-negative tests for any touched invariant.
- Regenerate golden fixtures if canonical hash algorithm changes.
- Run `check-canonical-drift.sh`.

## Escalate human review when

- `graph_root_hash` canonicalization rule changes
- Patch record size or signature policy changes
- New arch_id without golden ELF
