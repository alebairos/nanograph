#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

make -C tools -s all

export NANOGRAPH_ROOT="$ROOT"
RT_DIR="$(mktemp -d)"
trap 'rm -rf "$RT_DIR"' EXIT
mkdir -p "$RT_DIR/fixtures"

tools/bin/print-42-fixture --no-write --print-hash >/tmp/ngb-print-42-hash-new.txt
GOLDEN_HASH="$(tools/bin/ngb-parse fixtures/print_42.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
NEW_HASH="$(cat /tmp/ngb-print-42-hash-new.txt)"
[[ "$GOLDEN_HASH" == "$NEW_HASH" ]] || {
  echo "hash mismatch golden=$GOLDEN_HASH new=$NEW_HASH" >&2
  exit 1
}

NANOGRAPH_ROOT="$RT_DIR" tools/bin/print-42-fixture
cmp -s fixtures/print_42.ngb "$RT_DIR/fixtures/print_42.ngb" || {
  echo "print-42-fixture output differs from golden fixtures/print_42.ngb" >&2
  exit 1
}

tools/bin/ngb-parse fixtures/print_42.ngb >/dev/null
tools/bin/ngb-parse "$RT_DIR/fixtures/print_42.ngb" >/dev/null

echo "OK: print_42 ngb roundtrip"
