#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "LIVE-AGENT-PREREQS FAIL: $1" >&2; exit 1; }

command -v agent >/dev/null 2>&1 || fail "cursor agent CLI not found (curl https://cursor.com/install -fsS | bash)"

if [[ -z "${CURSOR_API_KEY:-}" ]]; then
  if ! agent status >/dev/null 2>&1; then
    fail "set CURSOR_API_KEY or run agent login"
  fi
fi

for f in \
  fixtures/print_42.ngb \
  fixtures/conformance/print_43_stdout.spec \
  scripts/agent-eval/two-agent-auditor.sh \
  .cursor/skills/live-ngb-author/SKILL.md; do
  [[ -f "$f" ]] || fail "missing $f"
done

make -C tools -s bin/ngb-patch bin/ngb-parse bin/ngb-microop bin/conf-eval >/dev/null

echo "LIVE-AGENT-PREREQS OK"
