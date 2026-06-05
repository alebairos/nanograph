#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ADD-TWO-CHAIN-PROOF FAIL: $1" >&2; exit 1; }

ADD_TWO_CHAIN_NGB_BYTES=605
GENESIS_HASH=5a74198abb4229f2a85dd2320f4e3d6fbc359c9c99da20556d7fa815a65a6cf2
PATCH1_HASH=84927f4f905ba047293c1c5d0e824d179249629e016c229e6a90a2c40424508f

filesize() {
  if stat --version >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f%z "$1"
  fi
}

echo "== add_two two-patch chain proof =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/add_two_chain.ngb ]] || fail "missing fixtures/add_two_chain.ngb"
BUILT_HASH="$(NANOGRAPH_ROOT="$ROOT" tools/bin/add-two-chain-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/add_two_chain.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift"
ngb_sz="$(filesize fixtures/add_two_chain.ngb)"
[[ "$ngb_sz" -eq "$ADD_TWO_CHAIN_NGB_BYTES" ]] || fail "size $ngb_sz (want $ADD_TWO_CHAIN_NGB_BYTES)"
echo "P1 OK graph_root_hash=$FILE_HASH ngb=${ngb_sz}B"

echo "-- P2 structural --"
tools/bin/ngb-parse fixtures/add_two_chain.ngb >/dev/null
echo "P2 OK"

echo "-- P3 behavioral --"
set +e
./scripts/run-linux-elf.sh fixtures/add_two_chain.ngb
exit_code=$?
set -e
[[ "$exit_code" -eq 4 ]] || fail "exit $exit_code (want 4)"
echo "P3 OK exit=4"

echo "-- P4 audit --"
[[ -f fixtures/add_two_chain.audit-log.golden ]] || fail "missing audit golden"
got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe audit-log fixtures/add_two_chain.ngb >"$got"
diff -u fixtures/add_two_chain.audit-log.golden "$got" || fail "audit-log drift"
patch_count="$(grep -c '^patch ' "$got" || true)"
[[ "$patch_count" -eq 2 ]] || fail "patch_count $patch_count (want 2)"
pre1="$(grep '^patch ' "$got" | sed -n '1s/.*precondition=\([0-9a-f]\{64\}\).*/\1/p')"
pre2="$(grep '^patch ' "$got" | sed -n '2s/.*precondition=\([0-9a-f]\{64\}\).*/\1/p')"
[[ "$pre1" == "$GENESIS_HASH" ]] || fail "patch1 precondition $pre1"
[[ "$pre2" == "$PATCH1_HASH" ]] || fail "patch2 precondition $pre2"
echo "P4 OK chain preconditions"

echo "-- P5 trace --"
[[ -f fixtures/add_two_chain.trace.golden ]] || fail "missing trace golden"
tools/bin/nano-probe trace fixtures/add_two_chain.ngb >"$got"
diff -u fixtures/add_two_chain.trace.golden "$got" || fail "trace drift"
echo "P5 OK"

echo "ADD-TWO-CHAIN-PROOF OK"
