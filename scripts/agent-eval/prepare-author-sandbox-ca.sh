#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "PREPARE-AUTHOR-SANDBOX-CA FAIL: $1" >&2; exit 1; }

[[ $# -ge 1 ]] || fail "usage: prepare-author-sandbox-ca.sh <sandbox_dir>"

SANDBOX="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
GENESIS_SRC="fixtures/ca/ca_rule30_patched.ngb"
SPEC_SRC="fixtures/ca/rule30.spec"
SKILL_SRC="scripts/agent-eval/sandbox/live-ngb-ca-author-SKILL.md"

for f in "$GENESIS_SRC" "$SPEC_SRC" "$SKILL_SRC"; do
  [[ -f "$f" ]] || fail "missing $f"
done

make -C tools -s bin/ngb-parse bin/nano-probe >/dev/null

rm -rf "$SANDBOX"
mkdir -p "$SANDBOX/bin" "$SANDBOX/author" "$SANDBOX/feedback"

cp "$GENESIS_SRC" "$SANDBOX/genesis.ngb"
cp "$SPEC_SRC" "$SANDBOX/intent.spec"
cp "$SKILL_SRC" "$SANDBOX/author/SKILL.md"
cp tools/bin/ngb-parse "$SANDBOX/bin/ngb-parse"
cp tools/bin/nano-probe "$SANDBOX/bin/nano-probe"
chmod +x "$SANDBOX/bin/ngb-parse" "$SANDBOX/bin/nano-probe"

: >"$SANDBOX/feedback/probe_bundle.txt"
: >"$SANDBOX/feedback/verdict.txt"

if find "$SANDBOX" -type l | grep -q .; then
  fail "sandbox must not contain symlinks"
fi

FORBIDDEN_RE='patch_off=4424|5a:1e|1e:5a|ca_rule30_v1|rule30\.golden|d2b660292d2b|NANO-GOALS|CA-CONFORMANCE'
if grep -rE "$FORBIDDEN_RE" "$SANDBOX" >/dev/null 2>&1; then
  fail "sandbox contains forbidden oracle leakage"
fi

(
  cd "$SANDBOX"
  find . -type f ! -path './MANIFEST.sha256' | sort | while read -r f; do
    if command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "${f#./}"
    else
      sha256sum "${f#./}"
    fi
  done
) >"$SANDBOX/MANIFEST.sha256"

echo "PREPARE-AUTHOR-SANDBOX-CA OK dir=$SANDBOX files=$(find "$SANDBOX" -type f | wc -l | tr -d ' ')"
