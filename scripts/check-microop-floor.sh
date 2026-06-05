#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "MICROOP-FLOOR FAIL: $1" >&2; exit 1; }

PATCHED_HASH=2a8f5f4e1a9e8a3d294253229bea6526cb80e5cc21165e422d563563956dd9c1
WANT_STDOUT=$'43\n'

ORACLE_SPEC="fixtures/conformance/print_43_stdout.spec"
STRING_OFF=151

echo "== micro-op floor (G10/G12) =="
make -C tools -s bin/ngb-microop bin/ngb-parse bin/conf-eval >/dev/null

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "-- static accept: rodata_byte_write on print_42 --"
set +e
accept_static="$(tools/bin/ngb-microop fixtures/print_42.ngb \
  fixtures/microop/print_42_rodata_43.microop "$WORK/patched.ngb" \
  --patch-id 1 --timestamp 1700000000)"
accept_code=$?
set -e
echo "$accept_static"
[[ "$accept_code" -eq 0 ]] || fail "expected static accept"
[[ "$accept_static" == *"static=accept"* ]] || fail "missing static=accept"

got_hash="$(tools/bin/ngb-parse "$WORK/patched.ngb" 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$got_hash" == "$PATCHED_HASH" ]] || fail "hash $got_hash != oracle $PATCHED_HASH"

stdout_file="$(mktemp)"
want_stdout="$(mktemp)"
printf '%s' "$WANT_STDOUT" >"$want_stdout"
set +e
./scripts/run-linux-elf-capture.sh "$WORK/patched.ngb" >"$stdout_file"
exit_code=$?
set -e
[[ "$exit_code" -eq 0 ]] || fail "ELF exit $exit_code (want 0)"
cmp -s "$want_stdout" "$stdout_file" || fail "stdout drift"
rm -f "$stdout_file" "$want_stdout"
echo "behavior OK stdout=43 exit=0"

echo "-- static reject: instruction byte offset --"
set +e
reject_static="$(tools/bin/ngb-microop fixtures/print_42.ngb \
  fixtures/microop/print_42_code_imm.microop /dev/null --check-only)"
reject_code=$?
set -e
echo "$reject_static"
[[ "$reject_code" -eq 1 ]] || fail "expected static reject for code offset"
[[ "$reject_static" == *"static=reject"* ]] || fail "missing static=reject"
[[ "$reject_static" == *"not_rodata"* ]] || fail "expected not_rodata invariant"

echo "-- value-bound (G12): expected digit derived from conf-eval --"
rendered="$(tools/bin/conf-eval "$ORACLE_SPEC")"
idx=$((152 - STRING_OFF))
digit="${rendered:$idx:1}"
expect_new="$(printf '%02x' "'$digit")"
echo "conf-eval rendered '${rendered%$'\n'}' digit[$idx]=$digit expect_new=$expect_new"

set +e
val_accept="$(tools/bin/ngb-microop fixtures/print_42.ngb \
  fixtures/microop/print_42_rodata_43.microop /dev/null --check-only --expect-new "$expect_new")"
val_accept_code=$?
set -e
echo "$val_accept"
[[ "$val_accept_code" -eq 0 ]] || fail "value-bound: expected accept for new=33"
[[ "$val_accept" == *"static=accept"* ]] || fail "value-bound: missing accept"

set +e
val_reject="$(tools/bin/ngb-microop fixtures/print_42.ngb \
  fixtures/microop/print_42_rodata_44.microop /dev/null --check-only --expect-new "$expect_new")"
val_reject_code=$?
set -e
echo "$val_reject"
[[ "$val_reject_code" -eq 1 ]] || fail "value-bound: expected reject for new=34"
[[ "$val_reject" == *"value_mismatch"* ]] || fail "value-bound: expected value_mismatch"

echo "MICROOP-FLOOR OK (accept rodata, reject code imm, value-bound accept/reject)"
