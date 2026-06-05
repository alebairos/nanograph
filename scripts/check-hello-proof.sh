#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "HELLO-PROOF FAIL: $1" >&2; exit 1; }
skip() { echo "HELLO-PROOF SKIP: $1"; }

echo "== canonical hello proof ladder =="

echo "-- P1 static --"
[[ -f fixtures/hello.ngb ]] || fail "missing fixtures/hello.ngb (run build-canonical-hello.py)"
[[ -f fixtures/hello_elf.bin ]] || fail "missing fixtures/hello_elf.bin"
python3 scripts/build-canonical-hello.py --print-hash >/tmp/ngb-hash.txt
BUILT_HASH="$(cat /tmp/ngb-hash.txt)"
FILE_HASH="$(python3 -c "import pathlib; d=pathlib.Path('fixtures/hello.ngb').read_bytes(); print(d[32:40].hex())")"
[[ "$BUILT_HASH" == "$FILE_HASH" ]] || fail "graph_root_hash drift (rebuild fixtures)"
echo "P1 OK graph_root_hash=$FILE_HASH"

echo "-- P2 structural --"
if [[ -x scripts/check-ngb-roundtrip.sh ]]; then
  ./scripts/check-ngb-roundtrip.sh
  echo "P2 OK"
else
  skip "check-ngb-roundtrip.sh not yet (M2)"
fi

echo "-- P3 behavioral --"
if [[ "$(uname -s)" == "Linux" ]]; then
  python3 -c "
import pathlib, os, stat, subprocess
ngb = pathlib.Path('fixtures/hello.ngb').read_bytes()
off = int.from_bytes(ngb[12:16], 'little')
ln = int.from_bytes(ngb[16:20], 'little')
elf = ngb[off:off+ln]
path = pathlib.Path('/tmp/nanograph-hello-test')
path.write_bytes(elf)
path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
subprocess.run([str(path)], check=True)
"
  echo "P3 OK ran ELF exit 0"
elif command -v qemu-x86_64 >/dev/null 2>&1; then
  python3 -c "
import pathlib, subprocess
ngb = pathlib.Path('fixtures/hello.ngb').read_bytes()
off = int.from_bytes(ngb[12:16], 'little')
ln = int.from_bytes(ngb[16:20], 'little')
elf = ngb[off:off+ln]
path = pathlib.Path('/tmp/nanograph-hello-test')
path.write_bytes(elf)
path.chmod(0o755)
subprocess.run(['qemu-x86_64', str(path)], check=True)
"
  echo "P3 OK qemu exit 0"
else
  skip "P3 needs Linux or qemu-x86_64 (M2 gate on CI)"
fi

echo "-- P4 audit --"
if [[ -x scripts/check-probe-audit-log.sh ]]; then
  ./scripts/check-probe-audit-log.sh
  echo "P4 OK"
else
  skip "check-probe-audit-log.sh not yet (M3)"
fi

echo "HELLO-PROOF OK (all present layers passed)"
