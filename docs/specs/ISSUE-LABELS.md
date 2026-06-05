# Issue labels

Use GitHub Issues to persist work units. Milestones (`M0–M4`) stay in [`MILESTONES.md`](MILESTONES.md). Issues track execution, PR linkage, and closure.

## Label groups

| Group | Labels | Rule |
| --- | --- | --- |
| milestone | `milestone:m0` … `milestone:m4` | Exactly 1 when using issues |
| type | `type:feature`, `type:bug`, `type:chore`, `type:docs`, `type:harness` | Exactly 1 required |
| area | `area:ngb`, `area:probe`, `area:harness`, `area:docs` | Optional, max 1 |
| meta | `meta:umbrella` | Optional; parent tracking issue |

## Query ready work

```bash
gh issue list --search "is:open label:milestone:m1 label:type:feature" --json number,title,labels
```

## Issue body template

```markdown
## Problem

## Acceptance

- [ ] …

## Milestone

Bound milestone: M*n*

## Verification

- [ ] ./scripts/check-canonical-drift.sh
- [ ] (milestone-gate commands)
```
