#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ADD-TWO-PATCHED-PROOF FAIL: $1" >&2; exit 1; }

ADD_TWO_PATCHED_NGB_BYTES=475
ADD_TWO_PATCHED_EXIT=3
GENESIS_HASH=5a74198abb4229f2a85dd2320f4e3d6fbc359c9c99da20556d7fa815a65a6cf2

filesize() {
  if stat --version >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f%z "$1"
  fi
}

echo "== add_two patched proof ladder =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/add_two_patched.ngb ]] || fail "missing fixtures/add_two_patched.ngb"
BUILT_HASH="$(NANOGRAPH_ROOT="$ROOT" tools/bin/add-two-patch-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/add_two_patched.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift (rebuild fixtures)"
ngb_sz="$(filesize fixtures/add_two_patched.ngb)"
[[ "$ngb_sz" -eq "$ADD_TWO_PATCHED_NGB_BYTES" ]] || fail "add_two_patched.ngb size $ngb_sz (want $ADD_TWO_PATCHED_NGB_BYTES)"
echo "P1 OK graph_root_hash=$FILE_HASH ngb=${ngb_sz}B"

echo "-- P2 structural --"
tools/bin/ngb-parse fixtures/add_two_patched.ngb >/dev/null
echo "P2 OK"

echo "-- P3 behavioral --"
set +e
./scripts/run-linux-elf.sh fixtures/add_two_patched.ngb
exit_code=$?
set -e
[[ "$exit_code" -eq "$ADD_TWO_PATCHED_EXIT" ]] || fail "ELF exit $exit_code (want $ADD_TWO_PATCHED_EXIT)"
echo "P3 OK exit=$exit_code"

echo "-- P4 audit --"
[[ -f fixtures/add_two_patched.audit-log.golden ]] || fail "missing audit golden"
got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe audit-log fixtures/add_two_patched.ngb >"$got"
diff -u fixtures/add_two_patched.audit-log.golden "$got" || fail "audit-log stdout drift"
pre="$(grep '^patch ' "$got" | sed -n 's/.*precondition=\([0-9a-f]\{64\}\).*/\1/p' | head -1)"
[[ "$pre" == "$GENESIS_HASH" ]] || fail "patch precondition $pre (want genesis $GENESIS_HASH)"
echo "P4 OK precondition=$pre"

echo "ADD-TWO-PATCHED-PROOF OK (all layers passed)"
