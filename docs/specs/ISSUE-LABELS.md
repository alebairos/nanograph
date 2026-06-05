# Issue labels

Use GitHub Issues to persist work units. Technical milestones **M0–M7** and product proof **P01–P20** are tracked via labels.

## Label groups

| Group | Labels | Rule |
| --- | --- | --- |
| milestone | `milestone:m0` … `milestone:m7` | Technical milestone issues |
| milestone | `milestone:p01` … `milestone:p20` | Product proof steps |
| type | `type:feature`, `type:bug`, `type:chore`, `type:docs`, `type:harness`, `type:product-proof` | Exactly 1 required |
| area | `area:ngb`, `area:probe`, `area:harness`, `area:docs` | Optional, max 1 |
| meta | `meta:umbrella`, `meta:product-program` | Optional tracking |

## Query ready work

```bash
gh issue list --search "is:open label:milestone:p01 label:type:product-proof" --json number,title,labels
```

## Issue body template

```markdown
## Problem

## Acceptance

- [ ] …

## Milestone

Bound milestone: M*n* or P*n*

## Verification

- [ ] ./scripts/check-canonical-drift.sh
- [ ] ./scripts/check-all-proofs.sh
```
