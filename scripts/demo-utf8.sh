#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# The G27 demo for a human audience. A UTF-8 decoder ships the classic overlong
# hole. A fixed unit test stays green on it. NanoGraph's round_trip relation
# rejects it and names the offending bytes. Reuses the committed fixtures.

say() { printf '%s\n' "$*"; }
rule() { printf '%s\n' "------------------------------------------------------------"; }

REQ="fixtures/metamorphic/utf8.req"
HONEST="fixtures/metamorphic/utf8.ngb"
BUGGY="fixtures/metamorphic/utf8_overlong.ngb"
SRC="fixtures/metamorphic/utf8.c"
RELATION="./scripts/agent-eval/metamorphic-verify.sh"
BATCH="./scripts/run-linux-elf-batch.sh"

if ! ./scripts/check-linux-runner.sh --quiet; then
  say "demo-utf8: needs a Linux ELF runner (Linux, qemu-x86_64, or docker)."
  exit 1
fi
for f in "$REQ" "$HONEST" "$BUGGY" "$SRC"; do
  [[ -f "$f" ]] || { say "demo-utf8: missing $f (run scripts/mint-metamorphic-fixtures.sh)"; exit 1; }
done

batch_mode() {
  local ngb="$1" mode="$2"
  while read -r v; do [[ -z "$v" ]] && continue; printf '%s %s\n' "$mode" "$v"; done \
    | "$BATCH" "$ngb" 2>/dev/null | awk '{print $3}'
}

rule
say "NanoGraph demo: a passing unit test that hides a real bug"
rule
say "The artifact is a UTF-8 codec. The decoder has one slip: it accepts"
say "overlong encodings. C0 80 is a non-canonical, longer encoding of U+0000."
say "Accepting it is a textbook security hole, used to smuggle bytes past"
say "filters that only check the canonical form."
say ""
say "The slip is one compiled-out check. This is what the honest build keeps"
say "and the buggy build drops:"
say ""
grep -n -B1 'OVERLONG_OK' "$SRC" | sed 's/^/    /'
say ""

rule
say "Step 1. The unit test a developer would write."
say "For valid codepoints, decode(encode(cp)) must equal cp."
rule
canon=(0 65 233 8364 128512)
names=("U+0000 NUL" "U+0041 A" "U+00E9 e-acute" "U+20AC euro" "U+1F600 emoji")
packed=()
while read -r p; do packed+=("$p"); done < <(printf '%s\n' "${canon[@]}" | batch_mode "$BUGGY" enc)
decoded=()
while read -r d; do decoded+=("$d"); done < <(printf '%s\n' "${packed[@]}" | batch_mode "$BUGGY" dec)
pass=0
for i in "${!canon[@]}"; do
  cp="${canon[$i]}"; got="${decoded[$i]:-}"
  if [[ "$got" == "$cp" ]]; then
    say "  [PASS] ${names[$i]}: decode(encode($cp)) = $got"
    pass=$((pass + 1))
  else
    say "  [FAIL] ${names[$i]}: got $got"
  fi
done
say ""
say "  Result on the BUGGY binary: $pass/${#canon[@]} pass. The suite is green."
say "  A reviewer sees green and ships. The bug is invisible to this test,"
say "  because it only exercises canonical input."
say ""

rule
say "Step 2. NanoGraph runs the relation a developer would not."
say "For every byte sequence the decoder accepts, encode(decode(b)) must"
say "equal b. A correct decoder accepts only canonical encodings, so this"
say "holds. The sweep includes malformed input the unit test never tries."
rule
set +e
out="$("$RELATION" "$BUGGY" "$REQ" 2>/dev/null)"
set -e
say "  $out"
say ""
witness="$(printf '%s' "$out" | sed -n 's/.*hex=\([0-9A-F]*\).*/\1/p')"
say "  Verdict: REJECT. Witness bytes: $witness (the overlong NUL C0 80)."
say "  It decodes to U+0000 and re-encodes to the canonical 00, so the"
say "  round trip does not close. NanoGraph hands back the exact bytes."
say ""

rule
say "Step 3. The honest codec, same relation."
rule
out="$("$RELATION" "$HONEST" "$REQ" 2>/dev/null)" || { say "  unexpected: honest codec rejected"; exit 1; }
say "  $out"
say "  Verdict: ACCEPT. The honest decoder rejects the malformed input, so"
say "  every accepted sequence round-trips."
say ""

rule
say "The contrast. The unit test passed. NanoGraph rejected the same binary"
say "and explained why, in bytes. That gap is the product."
rule
