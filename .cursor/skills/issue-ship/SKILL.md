---
name: issue-ship
description: Link NanoGraph PRs to issues and finalize issue closure.
---

# Issue ship

Use when opening PRs or finishing implementation.

## Steps

1. PR body references issue (`Fixes #<id>` or `Refs #<id>`).
2. Working tree clean before PR (`git status` empty or only intentional unstaged).
3. Post ship summary on the issue with PR link, verification commands run, remaining follow-ups.
4. Close issue only when acceptance checklist is complete.
5. Run `./scripts/update-story.sh` and commit `docs/STORY-SO-FAR.md` if the chronicle changed.

## Command patterns

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
Fixes #<id>

## Summary
- ...

## Test plan
- [ ] ./scripts/check-canonical-drift.sh
EOF
)"

gh issue comment <id> --body-file /tmp/ship-summary.md
```

No eval bundle or agency.sh in this repo.
