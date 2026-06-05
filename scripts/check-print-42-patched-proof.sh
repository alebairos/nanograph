#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PRINT-42-PATCHED-PROOF FAIL: $1" >&2; exit 1; }

PRINT_42_PATCHED_NGB_BYTES=540
PRINT_42_PATCHED_STDOUT=$'43\n'
GENESIS_HASH=2429c3ed702dbfa62e4ab9eb2547b509f188b63f14742befa49dcee71f8cf016

filesize() {
  if stat --version >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f%z "$1"
  fi
}

echo "== print_42 patched proof ladder =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/print_42_patched.ngb ]] || fail "missing fixtures/print_42_patched.ngb"
BUILT_HASH="$(NANOGRAPH_ROOT="$ROOT" tools/bin/print-42-patch-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/print_42_patched.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift"
ngb_sz="$(filesize fixtures/print_42_patched.ngb)"
[[ "$ngb_sz" -eq "$PRINT_42_PATCHED_NGB_BYTES" ]] || fail "size $ngb_sz (want $PRINT_42_PATCHED_NGB_BYTES)"
echo "P1 OK graph_root_hash=$FILE_HASH ngb=${ngb_sz}B"

echo "-- P2 structural --"
tools/bin/ngb-parse fixtures/print_42_patched.ngb >/dev/null
echo "P2 OK"

echo "-- P3 behavioral --"
stdout_file="$(mktemp)"
want_stdout="$(mktemp)"
printf '%s' "$PRINT_42_PATCHED_STDOUT" >"$want_stdout"
set +e
./scripts/run-linux-elf-capture.sh fixtures/print_42_patched.ngb >"$stdout_file"
exit_code=$?
set -e
[[ "$exit_code" -eq 0 ]] || fail "ELF exit $exit_code (want 0)"
cmp -s "$want_stdout" "$stdout_file" || fail "stdout drift"
rm -f "$stdout_file" "$want_stdout"
echo "P3 OK stdout=43 exit=0"

echo "-- P4 audit --"
[[ -f fixtures/print_42_patched.audit-log.golden ]] || fail "missing audit golden"
got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe audit-log fixtures/print_42_patched.ngb >"$got"
diff -u fixtures/print_42_patched.audit-log.golden "$got" || fail "audit-log drift"
pre="$(grep '^patch ' "$got" | sed -n 's/.*precondition=\([0-9a-f]\{64\}\).*/\1/p' | head -1)"
[[ "$pre" == "$GENESIS_HASH" ]] || fail "precondition $pre"
echo "P4 OK"

echo "PRINT-42-PATCHED-PROOF OK"
