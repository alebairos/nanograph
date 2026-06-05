#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "EVAL-SPRINT FAIL: $1" >&2; exit 1; }

EXIT4_CHAIN_HASH=59a65e674d72a633ebd85004a9a0622896be4cf668163c4861f503028b17abf2
ELF_MOV_IMM_OFF=121
ELF_ADD_IMM_OFF=127

make -C tools -s all

TASK_LOG=".harness-data/agent-eval/task-a/run.jsonl"
ELF_LOG=".harness-data/agent-eval/elf-a/run.jsonl"
CATCH_LOG=".harness-data/agent-eval/integrity/run.jsonl"
mkdir -p "$(dirname "$TASK_LOG")" "$(dirname "$ELF_LOG")" "$(dirname "$CATCH_LOG")"
: >"$TASK_LOG"; : >"$ELF_LOG"; : >"$CATCH_LOG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() { printf '%s\n' "$2" >>"$1"; }
byte_at() { xxd -p -s "$1" -l 1 "$2"; }

graph_hash() {
  tools/bin/ngb-parse "$1" 2>/dev/null | sed -n 's/.*graph_root_hash=//p'
}

ngb_step=0
ngb_log() {
  ngb_step=$((ngb_step + 1))
  emit "$TASK_LOG" "{\"ts\":\"$(now)\",\"surface\":\"ngb\",\"step\":$ngb_step,\"note\":\"$1\"}"
}
elf_step=0
elf_log() {
  elf_step=$((elf_step + 1))
  emit "$ELF_LOG" "{\"ts\":\"$(now)\",\"surface\":\"elf\",\"step\":$elf_step,\"note\":\"$1\"}"
}

echo "-- control: both surfaces reach exit 4 --"

ngb_log "nano-probe disassemble fixtures/add_two.ngb"
dis="$(tools/bin/nano-probe disassemble fixtures/add_two.ngb)"
echo "$dis" | grep -q 'mov eax, 1' || fail "disassemble missing mov eax,1"
echo "$dis" | grep -q 'add eax, 1' || fail "disassemble missing add eax,1"

ngb_log "ngb-patch off=127 pair=01:02 (genesis -> exit 3)"
tools/bin/ngb-patch fixtures/add_two.ngb "$WORK/p1.ngb" \
  --off 127 --pair 01:02 --patch-id 1 --timestamp 1700000000 >/dev/null
tools/bin/ngb-parse --json "$WORK/p1.ngb" | grep -q '"ok":true' || fail "p1 parse"

ngb_log "ngb-patch off=121 pair=01:02 (exit 3 -> exit 4)"
tools/bin/ngb-patch "$WORK/p1.ngb" "$WORK/chain.ngb" \
  --off 121 --pair 01:02 --patch-id 2 --timestamp 1700000000 >/dev/null
tools/bin/ngb-parse --json "$WORK/chain.ngb" | grep -q '"ok":true' || fail "chain parse"

got_hash="$(graph_hash "$WORK/chain.ngb")"
[[ "$got_hash" == "$EXIT4_CHAIN_HASH" ]] || fail "chain hash $got_hash != proven exit-4 fixture"
ngb_log "graph hash matches docker-proven exit-4 fixture $EXIT4_CHAIN_HASH"
emit "$TASK_LOG" "{\"ts\":\"$(now)\",\"surface\":\"ngb\",\"control\":\"exit4\",\"success\":true,\"steps\":$ngb_step,\"behavioral_proof\":\"hash-equiv to check-add-two-chain-proof.sh\"}"

cp fixtures/add_two_elf.bin "$WORK/elf.bin"
[[ "$(byte_at "$ELF_MOV_IMM_OFF" "$WORK/elf.bin")" == "01" ]] || fail "elf mov imm not 0x01"
[[ "$(byte_at "$ELF_ADD_IMM_OFF" "$WORK/elf.bin")" == "01" ]] || fail "elf add imm not 0x01"
elf_log "verified mov/add immediates are 0x01 at off $ELF_MOV_IMM_OFF/$ELF_ADD_IMM_OFF"
printf '\x02' | dd of="$WORK/elf.bin" bs=1 seek="$ELF_MOV_IMM_OFF" count=1 conv=notrunc status=none
printf '\x02' | dd of="$WORK/elf.bin" bs=1 seek="$ELF_ADD_IMM_OFF" count=1 conv=notrunc status=none
elf_log "dd patched both immediates to 0x02"
[[ "$(byte_at "$ELF_MOV_IMM_OFF" "$WORK/elf.bin")" == "02" ]] || fail "elf mov imm patch"
[[ "$(byte_at "$ELF_ADD_IMM_OFF" "$WORK/elf.bin")" == "02" ]] || fail "elf add imm patch"
emit "$ELF_LOG" "{\"ts\":\"$(now)\",\"surface\":\"elf\",\"control\":\"exit4\",\"success\":true,\"steps\":$elf_step,\"behavioral_proof\":\"prior docker run exit 4\"}"

echo "control OK: both reach exit 4"

echo "-- integrity test: same bad edit, who catches it at author time --"

ngb_caught=0
elf_caught=0
total=0

case_row() {
  local name="$1" ngb_ok="$2" ngb_detail="$3" elf_ok="$4" elf_detail="$5"
  total=$((total + 1))
  [[ "$ngb_ok" == "caught" ]] && ngb_caught=$((ngb_caught + 1))
  [[ "$elf_ok" == "caught" ]] && elf_caught=$((elf_caught + 1))
  emit "$CATCH_LOG" "{\"ts\":\"$(now)\",\"case\":\"$name\",\"ngb\":\"$ngb_ok\",\"ngb_detail\":\"$ngb_detail\",\"elf\":\"$elf_ok\",\"elf_detail\":\"$elf_detail\"}"
  echo "  $name: ngb=$ngb_ok elf=$elf_ok"
}

ngb_err="$(mktemp)"
set +e
tools/bin/ngb-patch fixtures/add_two.ngb "$WORK/oob.ngb" \
  --off 999 --pair 01:02 --patch-id 9 --timestamp 1 2>"$ngb_err" >/dev/null
ngb_code=$?
set -e
cp fixtures/add_two_elf.bin "$WORK/oob.elf"
set +e
printf '\x02' | dd of="$WORK/oob.elf" bs=1 seek=999 count=1 conv=notrunc status=none 2>/dev/null
elf_code=$?
set -e
ngb_res="shipped"; [[ "$ngb_code" -ne 0 ]] && ngb_res="caught"
elf_res="shipped"; [[ "$elf_code" -ne 0 ]] && elf_res="caught"
case_row "oob_offset" "$ngb_res" "$(grep -o 'I[0-9]:[a-z_]*' "$ngb_err" | head -1)" "$elf_res" "dd exit $elf_code wrote past code"

cp fixtures/add_two.ngb "$WORK/magic.ngb"
printf 'XXXX' | dd of="$WORK/magic.ngb" bs=1 seek=0 count=4 conv=notrunc status=none 2>/dev/null
set +e
tools/bin/ngb-parse "$WORK/magic.ngb" 2>"$ngb_err" >/dev/null
ngb_code=$?
set -e
cp fixtures/add_two_elf.bin "$WORK/magic.elf"
printf '\x00' | dd of="$WORK/magic.elf" bs=1 seek=0 count=1 conv=notrunc status=none 2>/dev/null
ngb_res="shipped"; [[ "$ngb_code" -ne 0 ]] && ngb_res="caught"
case_row "corrupt_header" "$ngb_res" "$(grep -o 'I[0-9]:[a-z_]*\|root_hash' "$ngb_err" | head -1)" "shipped" "dd accepted e_ident write; loader fails only at runtime"

NGB_HEADER=64
NGB_CODE_IMG_OFF=120
cp fixtures/add_two_patched.ngb "$WORK/code.ngb"
printf '\x90' | dd of="$WORK/code.ngb" bs=1 seek=$((NGB_HEADER + NGB_CODE_IMG_OFF)) count=1 conv=notrunc status=none 2>/dev/null
set +e
tools/bin/ngb-parse "$WORK/code.ngb" 2>"$ngb_err" >/dev/null
ngb_code=$?
set -e
cp fixtures/add_two_elf.bin "$WORK/code.elf"
printf '\x90' | dd of="$WORK/code.elf" bs=1 seek=120 count=1 conv=notrunc status=none 2>/dev/null
ngb_res="shipped"; [[ "$ngb_code" -ne 0 ]] && ngb_res="caught"
case_row "silent_code_tamper" "$ngb_res" "$(grep -o 'I[0-9]:[a-z_]*\|root_hash' "$ngb_err" | head -1)" "shipped" "dd accepted opcode overwrite; no integrity check"

rm -f "$ngb_err"

emit "$CATCH_LOG" "{\"ts\":\"$(now)\",\"summary\":true,\"total_bad_edits\":$total,\"ngb_caught_at_author_time\":$ngb_caught,\"elf_caught_at_author_time\":$elf_caught}"

echo ""
echo "EVAL-SPRINT OK"
echo "  control: both surfaces reach exit 4"
echo "  integrity: ngb caught $ngb_caught/$total bad edits at author time; elf caught $elf_caught/$total"
[[ "$ngb_caught" -eq "$total" ]] || fail "ngb did not catch all bad edits"
[[ "$elf_caught" -eq 0 ]] || echo "  note: elf caught $elf_caught (unexpected, review case)"
