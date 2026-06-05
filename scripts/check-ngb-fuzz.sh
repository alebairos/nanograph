#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "NGB-FUZZ FAIL: $1" >&2; exit 1; }

TRIALS="${1:-1000}"
SEED="${2:-1}"
LOG=".harness-data/agent-eval/fuzz/run.jsonl"
mkdir -p "$(dirname "$LOG")"

make -C tools -s all

echo "== ngb-fuzz: $TRIALS random image mutations, ngb vs structural ELF check =="
out="$(tools/bin/ngb-fuzz fixtures/add_two.ngb fixtures/add_two_elf.bin --trials "$TRIALS" --seed "$SEED")"
echo "$out"

ngb_caught="$(echo "$out" | sed -n 's/.*ngb_caught=\([0-9]*\).*/\1/p')"
elf_caught="$(echo "$out" | sed -n 's/.*elf_caught=\([0-9]*\).*/\1/p')"
[[ "$ngb_caught" -eq "$TRIALS" ]] || fail "ngb caught $ngb_caught/$TRIALS (content hashing must catch every image mutation)"
[[ "$ngb_caught" -gt "$elf_caught" ]] || fail "no integrity gap: ngb $ngb_caught vs elf $elf_caught"

printf '{"ts":"%s","test":"ngb-fuzz","trials":%s,"seed":%s,"ngb_caught":%s,"elf_caught":%s}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TRIALS" "$SEED" "$ngb_caught" "$elf_caught" >"$LOG"

echo "NGB-FUZZ OK ngb=$ngb_caught/$TRIALS elf=$elf_caught/$TRIALS log=$LOG"
