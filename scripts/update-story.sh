#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/STORY-SO-FAR.md"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "update-story: not a git repo" >&2
  exit 1
fi

{
  cat <<'EOF'
# Story so far

Lab-notebook chronicle of NanoGraph. **Regenerated from git.** Do not edit the chronicle section by hand.

```bash
./scripts/update-story.sh
```

Write commit subjects that stand alone. `Refs #n` links issues; the subject is the one-liner future readers see.

## Chronicle

EOF
  git log --reverse --format='- **%ad** — %s (`%h`)' --date=short
  echo ""
  echo "_$(git rev-list --count HEAD) entries · HEAD \`$(git rev-parse --short HEAD)\`_"
} >"$OUT"

echo "wrote $OUT"
