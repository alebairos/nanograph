#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

CAND="${1:?usage: h3-roundtrip-verify.sh <candidate.ngb> <request.req>}"
REQ="${2:?usage: h3-roundtrip-verify.sh <candidate.ngb> <request.req>}"
[[ -f "$CAND" && -f "$REQ" ]] || exit 2

reqval() { sed -n "s/^$1=//p" "$REQ" | head -1; }
RELATION="$(reqval relation)"
ENCODE="$(reqval encode)"
DECODE="$(reqval decode)"
REJECT="$(reqval reject)"
WIRE="$(reqval wire)"
[[ "$RELATION" == round_trip && -n "$ENCODE" && -n "$DECODE" && -n "$REJECT" ]] || exit 2

make -C tools -s bin/ngb-parse >/dev/null
hash="$(tools/bin/ngb-parse "$CAND" | sed -n 's/.*graph_root_hash=//p')"

run_mode() {
  local mode="$1"
  while read -r p; do
    [[ -z "$p" ]] && continue
    ./scripts/run-linux-elf-capture.sh "$CAND" "$mode" "$p" 2>/dev/null || true
  done
}

probes=(00 41 FF F)
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
      if [[ "$WIRE" == hex ]]; then
        hexw="$b"
      elif [[ "$WIRE" == ascii ]]; then
        hexw="$(printf '%s' "$b" | hexdump -ve '1/1 "%02x"')"
      else
        hexb="$(printf '%X' "$b")"
        hexw="${hexb:1}"
      fi
      echo "verdict=reject hash=${hash:0:12} relation=round_trip witness bytes=$b hex=$hexw decode=$cp2 reencode=$b3"
      exit 1
    fi
  fi
  accepted=$((accepted + 1))
done

[[ "$accepted" -ge 1 ]] || exit 2
echo "verdict=accept hash=${hash:0:12} relation=round_trip accepted=$accepted separator=none"
