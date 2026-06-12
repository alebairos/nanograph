#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ICP-SIM-SANDBOX FAIL: $1" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

./scripts/agent-eval/prepare-icp-sim-sandbox.sh "$WORK/sandbox" >/dev/null

SANDBOX="$WORK/sandbox"

[[ -f "$SANDBOX/README.md" ]] || fail "missing README.md"
[[ -f "$SANDBOX/docs/ADOPTION.md" ]] || fail "missing docs/ADOPTION.md"
[[ -x "$SANDBOX/nanograph" ]] || fail "missing executable ./nanograph"
[[ -f "$SANDBOX/PERSONA.md" ]] || fail "missing PERSONA.md"
[[ -f "$SANDBOX/maintainer-home/hex.c" ]] || fail "missing maintainer-home/hex.c"
[[ -f "$SANDBOX/MANIFEST.sha256" ]] || fail "missing MANIFEST.sha256"
[[ ! -d "$SANDBOX/.cursor" ]] || fail ".cursor leaked into sandbox"
[[ ! -d "$SANDBOX/.harness-data" ]] || fail ".harness-data leaked into sandbox"

# Persona must not leak internal harness vocabulary that would steer the agent.
FORBIDDEN_RE='NANO-GOALS|loop_state|nanograph-loop-driver|Bound issue|product_proof'
if grep -rE "$FORBIDDEN_RE" "$SANDBOX/PERSONA.md" >/dev/null 2>&1; then
  fail "persona contains internal harness vocabulary"
fi

echo "ICP-SIM-SANDBOX OK"
