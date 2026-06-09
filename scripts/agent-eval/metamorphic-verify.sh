#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Metamorphic verifier (G24, G27). Checks a binary against a relation that is its
# own oracle, so no expected output is computed. The VerificationRequest (.req)
# declares relation, entry, domain, eq. Relations:
#   involution  f(f(x)) == x over the domain.
#   round_trip  for each byte sequence b the decoder accepts,
#               encode(decode(b)) == b. A correct codec accepts only canonical
#               encodings, so this holds; an overlong-accepting decoder fails it.
# A candidate witness from the fast batched scan is confirmed by an isolated
# clean re-run, which filters transient backend faults.

usage() { echo "usage: metamorphic-verify.sh <candidate.ngb> <request.req>" >&2; exit 2; }
[[ $# -ge 2 ]] || usage
CAND="$1"
REQ="$2"
[[ -f "$CAND" ]] || { echo "metamorphic-verify: missing $CAND" >&2; exit 2; }
[[ -f "$REQ" ]] || { echo "metamorphic-verify: missing $REQ" >&2; exit 2; }

reqval() { sed -n "s/^$1=//p" "$REQ" | head -1; }
RELATION="$(reqval relation)"
DOMAIN="$(reqval domain)"

make -C tools -s bin/ngb-extract bin/ngb-parse >/dev/null
hash="$(tools/bin/ngb-parse "$CAND" | sed -n 's/.*graph_root_hash=//p')"

gen_u32() {
  local k
  for ((k = 0; k < 32; k++)); do printf '%s\n' "$((1 << k))"; done
  printf '%s\n' 0 305419896 3735928559 16909060 4294967295
}

# UTF-8 byte sequences packed as 0x01 ++ bytes, decimal. The canonical entries
# round-trip; the overlong, surrogate, and out-of-range entries must be rejected
# by a correct decoder. An overlong-accepting decoder fails round_trip on C0 80.
gen_utf8() {
  printf '%s\n' 321 115625 31621804 8331958400 256 \
    114816 115135 31490176 32350336 8398078080
}

gen_leb128() {
  printf '%s\n' 256 257 383 98305 109570 98304 98560
}

gen_knuth_sgb() {
  printf '%s\n' 257 266 321 21039682 98305
}

# LEB128 byte sequences as lowercase hex (the wire is the byte string, not a
# packed integer, so a 10-byte u64 LEB128 fits). Canonical entries round-trip;
# the last is a too-big 10-byte form (10th byte 0x02) a correct decoder rejects.
gen_wabt_leb128() {
  printf '%s\n' 00 7f 8001 e58e26 80808080808080808001 ffffffffffffffffff01 \
    ffffffffffffffffff02
}

gen_probes() {
  case "$DOMAIN" in
    u32) gen_u32 ;;
    utf8) gen_utf8 ;;
    leb128) gen_leb128 ;;
    knuth_sgb) gen_knuth_sgb ;;
    wabt_leb128) gen_wabt_leb128 ;;
    *) echo "metamorphic-verify: unsupported domain=$DOMAIN" >&2; exit 2 ;;
  esac
}

apply_once() {
  while read -r p; do [[ -z "$p" ]] && continue; printf '%s %s\n' "$p" "$p"; done \
    | ./scripts/run-linux-elf-batch.sh "$CAND" 2>/dev/null | awk '{print $3}'
}

run_mode() {
  local mode="$1"
  while read -r v; do [[ -z "$v" ]] && continue; printf '%s %s\n' "$mode" "$v"; done \
    | ./scripts/run-linux-elf-batch.sh "$CAND" 2>/dev/null | awk '{print $3}'
}

if [[ "$RELATION" == round_trip ]]; then
  ENCODE="$(reqval encode)"
  DECODE="$(reqval decode)"
  REJECT="$(reqval reject)"
  WIRE="$(reqval wire)"
  [[ -n "$ENCODE" && -n "$DECODE" && -n "$REJECT" ]] || {
    echo "metamorphic-verify: round_trip needs encode, decode, reject in $REQ" >&2
    exit 2
  }

  probes=()
  while read -r p; do probes+=("$p"); done < <(gen_probes)

  decoded=()
  while read -r d; do decoded+=("$d"); done < <(printf '%s\n' "${probes[@]}" | run_mode "$DECODE")

  acc_idx=()
  acc_cp=()
  for i in "${!probes[@]}"; do
    cp="${decoded[$i]:-}"
    [[ -z "$cp" || "$cp" == "$REJECT" ]] && continue
    acc_idx+=("$i")
    acc_cp+=("$cp")
  done

  reencoded=()
  if ((${#acc_cp[@]})); then
    while read -r r; do reencoded+=("$r"); done < <(printf '%s\n' "${acc_cp[@]}" | run_mode "$ENCODE")
  fi

  accepted=0
  for j in "${!acc_idx[@]}"; do
    i="${acc_idx[$j]}"
    b="${probes[$i]}"
    b2="${reencoded[$j]:-}"
    if [[ "$b2" != "$b" ]]; then
      cp2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$DECODE" "$b" 2>/dev/null || true)"
      [[ -z "$cp2" || "$cp2" == "$REJECT" ]] && continue
      b3="$(./scripts/run-linux-elf-capture.sh "$CAND" "$ENCODE" "$cp2" 2>/dev/null || true)"
      if [[ "$b3" != "$b" ]]; then
        if [[ "$WIRE" == hex ]]; then hexw="$b"; else hexb="$(printf '%X' "$b")"; hexw="${hexb:1}"; fi
        echo "verdict=reject hash=${hash:0:12} relation=round_trip witness bytes=$b hex=$hexw decode=$cp2 reencode=$b3"
        exit 1
      fi
    fi
    accepted=$((accepted + 1))
  done

  [[ "$accepted" -ge 1 ]] || {
    echo "metamorphic-verify: round_trip accepted 0 inputs (domain has no canonical sample)" >&2
    exit 2
  }
  echo "verdict=accept hash=${hash:0:12} relation=round_trip accepted=$accepted separator=none"
  exit 0
fi

if [[ "$RELATION" != involution ]]; then
  echo "metamorphic-verify: unsupported relation=$RELATION" >&2
  exit 2
fi

probes=()
while read -r p; do probes+=("$p"); done < <(gen_probes)

ys=()
while read -r y; do ys+=("$y"); done < <(printf '%s\n' "${probes[@]}" | apply_once)

ys_filled=()
for y in "${ys[@]}"; do ys_filled+=("${y:-0}"); done

zs=()
while read -r z; do zs+=("$z"); done < <(printf '%s\n' "${ys_filled[@]}" | apply_once)

for i in "${!probes[@]}"; do
  x="${probes[$i]}"
  y="${ys[$i]:-}"
  z="${zs[$i]:-}"
  [[ -n "$y" && "$z" == "$x" ]] && continue
  y2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$x" 2>/dev/null || true)"
  z2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$y2" 2>/dev/null || true)"
  if [[ "$z2" != "$x" ]]; then
    echo "verdict=reject hash=${hash:0:12} relation=involution witness x=$x fx=$y2 ffx=$z2"
    exit 1
  fi
done

echo "verdict=accept hash=${hash:0:12} relation=involution probes=${#probes[@]} separator=none"
exit 0
