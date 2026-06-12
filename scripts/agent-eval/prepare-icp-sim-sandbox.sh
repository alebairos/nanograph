#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "PREPARE-ICP-SIM-SANDBOX FAIL: $1" >&2; exit 1; }

[[ $# -ge 1 ]] || fail "usage: prepare-icp-sim-sandbox.sh <sandbox_dir>"

SANDBOX="$(mkdir -p "$1" && cd "$1" && pwd)"
PERSONA_SRC="scripts/agent-eval/sandbox/icp-maintainer-PERSONA.md"
HOME_SRC="scripts/agent-eval/sandbox/icp-maintainer-home"

[[ -f "$PERSONA_SRC" ]] || fail "missing $PERSONA_SRC"
[[ -d "$HOME_SRC" ]] || fail "missing $HOME_SRC"

rm -rf "$SANDBOX"
mkdir -p "$SANDBOX"

# git archive gives exactly what an external clone of HEAD sees.
git archive HEAD | tar -x -C "$SANDBOX"

# Internal harness steering must not contaminate the persona.
rm -rf "$SANDBOX/.cursor" "$SANDBOX/.harness-data"

mkdir -p "$SANDBOX/maintainer-home"
cp "$HOME_SRC"/* "$SANDBOX/maintainer-home/"
cp "$PERSONA_SRC" "$SANDBOX/PERSONA.md"

# Working-tree overlay for ICP-facing scripts so gates match the tree under edit.
# git archive alone reflects last commit; overlay keeps local sim and acceptance honest.
for rel in scripts/nanograph scripts/demo-utf8.sh scripts/agent-eval/metamorphic-verify.sh; do
  [[ -f "$ROOT/$rel" ]] || fail "missing overlay $rel"
  install -m 755 "$ROOT/$rel" "$SANDBOX/$rel"
done
for rel in docs/ADOPTION.md README.md \
  fixtures/templates/icp-hex-specimen.c fixtures/templates/icp-hex-roundtrip.req \
  docs/specs/METAMORPHIC-RELATIONS.md docs/specs/LANG-PACKS.md; do
  [[ -f "$ROOT/$rel" ]] || fail "missing overlay $rel"
  mkdir -p "$(dirname "$SANDBOX/$rel")"
  cp "$ROOT/$rel" "$SANDBOX/$rel"
done

[[ -f "$SANDBOX/README.md" ]] || fail "sandbox missing README.md"
[[ -x "$SANDBOX/nanograph" ]] || fail "sandbox missing executable ./nanograph"
[[ -d "$SANDBOX/.cursor" ]] && fail "sandbox still contains .cursor"
[[ -d "$SANDBOX/.harness-data" ]] && fail "sandbox still contains .harness-data"

if find "$SANDBOX" -type l | grep -q .; then
  fail "sandbox must not contain symlinks"
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

echo "PREPARE-ICP-SIM-SANDBOX OK dir=$SANDBOX files=$(find "$SANDBOX" -type f | wc -l | tr -d ' ')"
