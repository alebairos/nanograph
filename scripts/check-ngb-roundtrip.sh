#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

make -C tools -s all

export NANOGRAPH_ROOT="$ROOT"
tools/bin/hello-fixture --no-write --print-hash >/tmp/ngb-hash-new.txt
GOLDEN_HASH="$(tools/bin/ngb-parse fixtures/hello.ngb 2>/dev/null | sed -n 's/.*graph_root_hash=//p')"
NEW_HASH="$(cat /tmp/ngb-hash-new.txt)"
[[ "$GOLDEN_HASH" == "$NEW_HASH" ]] || {
  echo "hash mismatch golden=$GOLDEN_HASH new=$NEW_HASH" >&2
  exit 1
}

tools/bin/ngb-pack fixtures/hello_elf.bin /tmp/ngb-packed.ngb
cmp -s fixtures/hello.ngb /tmp/ngb-packed.ngb || {
  echo "ngb-pack output differs from golden fixtures/hello.ngb" >&2
  exit 1
}

tools/bin/ngb-parse fixtures/hello.ngb >/dev/null
tools/bin/ngb-parse /tmp/ngb-packed.ngb >/dev/null

echo "OK: ngb roundtrip"
