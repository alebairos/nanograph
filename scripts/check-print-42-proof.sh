#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PRINT-42-PROOF FAIL: $1" >&2; exit 1; }

PRINT_42_ELF_BYTES=154
PRINT_42_NGB_BYTES=410
PRINT_42_FIXTURE_MS_CEILING=50
PRINT_42_STDOUT=$'42\n'

filesize() {
  if stat --version >/dev/null 2>&1; then
    stat -c%s "$1"
  else
    stat -f%z "$1"
  fi
}

echo "== canonical print_42 proof ladder =="

make -C tools -s all

echo "-- P1 static --"
[[ -f fixtures/print_42.ngb ]] || fail "missing fixtures/print_42.ngb"
[[ -f fixtures/print_42_elf.bin ]] || fail "missing fixtures/print_42_elf.bin"
BUILT_HASH="$(tools/bin/print-42-fixture --no-write --print-hash)"
FILE_HASH="$(tools/bin/ngb-parse fixtures/print_42.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift (rebuild fixtures)"
elf_sz="$(filesize fixtures/print_42_elf.bin)"
ngb_sz="$(filesize fixtures/print_42.ngb)"
[[ "$elf_sz" -eq "$PRINT_42_ELF_BYTES" ]] || fail "print_42_elf.bin size $elf_sz (want $PRINT_42_ELF_BYTES)"
[[ "$ngb_sz" -eq "$PRINT_42_NGB_BYTES" ]] || fail "print_42.ngb size $ngb_sz (want $PRINT_42_NGB_BYTES)"
fixture_ms="$(tools/bin/print-42-fixture --no-write --print-ms)"
[[ "$fixture_ms" -le "$PRINT_42_FIXTURE_MS_CEILING" ]] || fail "print-42-fixture ${fixture_ms}ms exceeds budget"
echo "P1 OK graph_root_hash=$FILE_HASH elf=${elf_sz}B ngb=${ngb_sz}B fixture_ms=${fixture_ms}"

echo "-- P2 structural --"
./scripts/check-ngb-roundtrip-print-42.sh
echo "P2 OK"

echo "-- P3 behavioral --"
stdout_file="$(mktemp)"
want_stdout="$(mktemp)"
printf '%s' "$PRINT_42_STDOUT" >"$want_stdout"
set +e
./scripts/run-linux-elf-capture.sh fixtures/print_42.ngb >"$stdout_file"
exit_code=$?
set -e
[[ "$exit_code" -eq 0 ]] || fail "ELF exit $exit_code (want 0)"
cmp -s "$want_stdout" "$stdout_file" || fail "stdout drift (want 42 then newline)"
rm -f "$stdout_file" "$want_stdout"
echo "P3 OK stdout=42 exit=0"

echo "-- P4 audit --"
[[ -f fixtures/print_42.audit-log.golden ]] || fail "missing fixtures/print_42.audit-log.golden"
got="$(mktemp)"
trap 'rm -f "$got" "$stdout_file" "$want_stdout" 2>/dev/null || true' EXIT
tools/bin/nano-probe audit-log fixtures/print_42.ngb >"$got"
diff -u fixtures/print_42.audit-log.golden "$got" || fail "audit-log stdout drift"
echo "P4 OK"

echo "PRINT-42-PROOF OK (all layers passed)"
