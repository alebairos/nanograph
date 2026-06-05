#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "ADD-TWO-PROOF FAIL: $1" >&2; exit 1; }

ADD_TWO_ELF_BYTES=137
ADD_TWO_NGB_BYTES=345
ADD_TWO_FIXTURE_MS_CEILING=50
ADD_TWO_EXIT=2

filesize() {
  if stat --version >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f%z "$1"
  fi
}

echo "== canonical add_two proof ladder =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/add_two.ngb ]] || fail "missing fixtures/add_two.ngb (run tools/bin/add-two-fixture)"
[[ -f fixtures/add_two_elf.bin ]] || fail "missing fixtures/add_two_elf.bin"
BUILT_HASH="$(tools/bin/add-two-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/add_two.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift (rebuild fixtures)"
elf_sz="$(filesize fixtures/add_two_elf.bin)"
ngb_sz="$(filesize fixtures/add_two.ngb)"
[[ "$elf_sz" -eq "$ADD_TWO_ELF_BYTES" ]] || fail "add_two_elf.bin size $elf_sz (want $ADD_TWO_ELF_BYTES)"
[[ "$ngb_sz" -eq "$ADD_TWO_NGB_BYTES" ]] || fail "add_two.ngb size $ngb_sz (want $ADD_TWO_NGB_BYTES)"
fixture_ms="$(tools/bin/add-two-fixture --no-write --print-ms)"
[[ "$fixture_ms" -le "$ADD_TWO_FIXTURE_MS_CEILING" ]] || fail "add-two-fixture ${fixture_ms}ms exceeds budget"
echo "P1 OK graph_root_hash=$FILE_HASH elf=${elf_sz}B ngb=${ngb_sz}B fixture_ms=${fixture_ms}"

echo "-- P2 structural --"
./scripts/check-ngb-roundtrip-add-two.sh
echo "P2 OK"

echo "-- P3 behavioral --"
set +e
./scripts/run-linux-elf.sh fixtures/add_two.ngb
exit_code=$?
set -e
[[ "$exit_code" -eq "$ADD_TWO_EXIT" ]] || fail "ELF exit $exit_code (want $ADD_TWO_EXIT)"
echo "P3 OK exit=$exit_code"

echo "-- P4 audit --"
[[ -f fixtures/add_two.audit-log.golden ]] || fail "missing fixtures/add_two.audit-log.golden"
got="$(mktemp)"
trap 'rm -f "$got"' EXIT
tools/bin/nano-probe audit-log fixtures/add_two.ngb >"$got"
diff -u fixtures/add_two.audit-log.golden "$got" || fail "audit-log stdout drift"
echo "P4 OK"

echo "ADD-TWO-PROOF OK (all layers passed)"
