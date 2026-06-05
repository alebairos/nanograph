#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "HELLO-PROOF FAIL: $1" >&2; exit 1; }
skip() { echo "HELLO-PROOF SKIP: $1"; }

echo "== canonical hello proof ladder =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/hello.ngb ]] || fail "missing fixtures/hello.ngb (run tools/bin/hello-fixture)"
[[ -f fixtures/hello_elf.bin ]] || fail "missing fixtures/hello_elf.bin"
BUILT_HASH="$(tools/bin/hello-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/hello.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift (rebuild fixtures)"
echo "P1 OK graph_root_hash=$FILE_HASH"

echo "-- P2 structural --"
./scripts/check-ngb-roundtrip.sh
echo "P2 OK"

echo "-- P3 behavioral --"
./scripts/run-linux-elf.sh fixtures/hello.ngb
echo "P3 OK"

echo "-- P4 audit --"
if [[ -x scripts/check-probe-audit-log.sh ]]; then
  ./scripts/check-probe-audit-log.sh
  echo "P4 OK"
else
  skip "check-probe-audit-log.sh not yet (M3)"
fi

echo "HELLO-PROOF OK (all present layers passed)"
