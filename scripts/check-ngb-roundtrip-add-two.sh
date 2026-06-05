#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

make -C tools -s all

export NANOGRAPH_ROOT="$ROOT"
RT_DIR="$(mktemp -d)"
trap 'rm -rf "$RT_DIR"' EXIT
mkdir -p "$RT_DIR/fixtures"

tools/bin/add-two-fixture --no-write --print-hash >/tmp/ngb-add-two-hash-new.txt
GOLDEN_HASH="$(tools/bin/ngb-parse fixtures/add_two.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
NEW_HASH="$(cat /tmp/ngb-add-two-hash-new.txt)"
[[ "$GOLDEN_HASH" == "$NEW_HASH" ]] || {
  echo "hash mismatch golden=$GOLDEN_HASH new=$NEW_HASH" >&2
  exit 1
}

NANOGRAPH_ROOT="$RT_DIR" tools/bin/add-two-fixture
cmp -s fixtures/add_two.ngb "$RT_DIR/fixtures/add_two.ngb" || {
  echo "add-two-fixture output differs from golden fixtures/add_two.ngb" >&2
  exit 1
}

tools/bin/ngb-parse fixtures/add_two.ngb >/dev/null
tools/bin/ngb-parse "$RT_DIR/fixtures/add_two.ngb" >/dev/null

echo "OK: add_two ngb roundtrip"
