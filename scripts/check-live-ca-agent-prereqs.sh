#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "LIVE-CA-AGENT-PREREQS FAIL: $1" >&2; exit 1; }

command -v agent >/dev/null 2>&1 || fail "cursor agent CLI not found (curl https://cursor.com/install -fsS | bash)"

if [[ -z "${CURSOR_API_KEY:-}" ]]; then
  if ! agent status >/dev/null 2>&1; then
    fail "set CURSOR_API_KEY or run agent login"
  fi
fi

for f in \
  fixtures/ca/ca_rule30_patched.ngb \
  fixtures/ca/rule30.spec \
  fixtures/ca/ca_rule30_v1.ngb \
  scripts/agent-eval/two-agent-auditor.sh \
  scripts/agent-eval/prepare-author-sandbox-ca.sh \
  scripts/agent-eval/sandbox/live-ngb-ca-author-SKILL.md; do
  [[ -f "$f" ]] || fail "missing $f"
done

make -C tools -s bin/ngb-patch bin/ngb-parse bin/conf-eval bin/ca-rule30-patch-fixture >/dev/null

echo "LIVE-CA-AGENT-PREREQS OK"
