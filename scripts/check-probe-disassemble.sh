#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "PROBE-DISASSEMBLE FAIL: $1" >&2; exit 1; }

echo "== nano-probe disassemble proof =="

make -C tools -s all

check_one() {
  local ngb="$1"
  local golden="$2"
  [[ -f "$ngb" ]] || fail "missing $ngb"
  [[ -f "$golden" ]] || fail "missing $golden"
  local got
  got="$(mktemp)"
  tools/bin/nano-probe disassemble "$ngb" >"$got"
  diff -u "$golden" "$got" || fail "disassemble drift for $ngb"
  rm -f "$got"
  echo "OK $ngb"
}

check_one fixtures/hello.ngb fixtures/hello.disassemble.golden
check_one fixtures/add_two.ngb fixtures/add_two.disassemble.golden
check_one fixtures/add_two_patched.ngb fixtures/add_two_patched.disassemble.golden

echo "PROBE-DISASSEMBLE OK"
