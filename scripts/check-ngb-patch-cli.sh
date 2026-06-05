#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "NGB-PATCH-CLI FAIL: $1" >&2; exit 1; }

make -C tools -s bin/ngb-patch

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

tools/bin/ngb-patch fixtures/add_two.ngb "$WORK/patched.ngb" \
  --off 127 --pair 01:02 --patch-id 1 --timestamp 1700000000 >/dev/null

GOT_HASH="$(tools/bin/ngb-parse "$WORK/patched.ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
WANT_HASH="$(tools/bin/ngb-parse fixtures/add_two_patched.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$GOT_HASH" == "$WANT_HASH" ]] || fail "hash $GOT_HASH (want $WANT_HASH)"

set +e
./scripts/run-linux-elf.sh "$WORK/patched.ngb"
exit_code=$?
set -e
[[ "$exit_code" -eq 3 ]] || fail "exit $exit_code (want 3)"

echo "NGB-PATCH-CLI OK"
