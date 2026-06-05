#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PATCH-REJECT FAIL: $1" >&2; exit 1; }

expect_status() {
  local label="$1"
  local want="$2"
  shift 2
  local err
  err="$(mktemp)"
  set +e
  "$@" 2>"$err" >/dev/null
  local code=$?
  set -e
  if [[ "$code" -eq 0 ]]; then
    cat "$err" >&2
    rm -f "$err"
    fail "$label: expected failure got exit 0"
  fi
  if ! grep -q "$want" "$err"; then
    echo "stderr:" >&2
    cat "$err" >&2
    rm -f "$err"
    fail "$label: expected '$want' in stderr"
  fi
  rm -f "$err"
  echo "OK: $label"
}

ADD_TWO_PATCHED_PATCH_OFF=345

echo "== patch rejection suite =="
make -C tools -s all

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

expect_status "oob delta" "I3:node_range" \
  tools/bin/ngb-patch fixtures/add_two.ngb "$WORK/oob.ngb" \
  --off 9999 --pair 01:02 --patch-id 1 --timestamp 1700000000

cp fixtures/add_two.ngb "$WORK/bad_magic.ngb"
printf 'XXXX' | dd of="$WORK/bad_magic.ngb" bs=1 seek=0 count=4 conv=notrunc status=none 2>/dev/null
expect_status "corrupt magic" "I1:magic" tools/bin/ngb-parse "$WORK/bad_magic.ngb"

cp fixtures/add_two_patched.ngb "$WORK/odd_delta.ngb"
printf '\x03\x00\x00\x00' | dd of="$WORK/odd_delta.ngb" bs=1 \
  seek=$((ADD_TWO_PATCHED_PATCH_OFF + 76)) count=4 conv=notrunc status=none 2>/dev/null
expect_status "odd delta_len" "root_hash" tools/bin/ngb-parse "$WORK/odd_delta.ngb"

cp fixtures/add_two_patched.ngb "$WORK/bad_pre.ngb"
printf '\xff' | dd of="$WORK/bad_pre.ngb" bs=1 \
  seek=$((ADD_TWO_PATCHED_PATCH_OFF + 40)) count=1 conv=notrunc status=none 2>/dev/null
expect_status "wrong precondition" "root_hash" tools/bin/ngb-parse "$WORK/bad_pre.ngb"

echo "PATCH-REJECT OK"
