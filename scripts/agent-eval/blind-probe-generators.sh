#!/usr/bin/env bash
# G73 blind probe generators. Inputs are .req fields only (relation, wire,
# max_total, and declared hints flow_nm / seed_start / cmp_max / probe_style /
# probe_block). No CASE.md witnesses, no timeline reject lines, no hand
# PROBES=, no domain-keyed switches.

BLIND_BYTE_BUDGET="${METAMORPHIC_BLIND_BYTE:-256}"
BLIND_FLOW_BUDGET="${METAMORPHIC_BLIND_FLOW:-64}"
BLIND_U32_BUDGET="${METAMORPHIC_BLIND_U32:-256}"
BLIND_ASCII_BUDGET="${METAMORPHIC_BLIND_ASCII:-256}"
BLIND_HEX_BUDGET="${METAMORPHIC_BLIND_HEX:-256}"

blind_req_hint() {
  [[ -n "${REQ:-}" && -f "${REQ:-}" ]] || return 0
  sed -n "s/^$1=//p" "$REQ" | head -1
}

blind_gen_u32() {
  local i
  for ((i = 0; i < BLIND_U32_BUDGET; i++)); do
    printf '%s\n' "$i"
  done
}

blind_gen_seeds_256() {
  local s
  for ((s = 1; s <= 256; s++)); do
    printf '%s\n' "$s"
  done
}

blind_gen_cmp_pairs() {
  local i j max
  max="$(blind_req_hint cmp_max)"
  max="${max:-1}"
  for ((i = 0; i <= max; i++)); do
    for ((j = 0; j <= max; j++)); do
      printf '%s %s\n' "$i" "$j"
    done
  done
}

blind_gen_flow_triples() {
  local n m seed start nm
  nm="$(blind_req_hint flow_nm)"
  nm="${nm:-1 1}"
  read -r n m <<<"$nm"
  start="$(blind_req_hint seed_start)"
  start="${start:-0}"
  for ((seed = start; seed < start + BLIND_FLOW_BUDGET; seed++)); do
    printf '%s %s %s\n' "$n" "$m" "$seed"
  done
}

blind_gen_utf8_decimal() {
  python3 - "$BLIND_BYTE_BUDGET" <<'PY'
import sys
budget = int(sys.argv[1])
count = 0
for b in range(256):
    if count >= budget:
        break
    print(256 + b)
    count += 1
for hi in range(256):
    if count >= budget:
        break
    for lo in range(256):
        if count >= budget:
            break
        print(256 * 256 + 256 * hi + lo)
        count += 1
PY
}

blind_gen_hex_bytes() {
  python3 - "$BLIND_HEX_BUDGET" <<'PY'
import sys
budget = int(sys.argv[1])
count = 0
hexd = "0123456789abcdef"
for n in range(1, 9):
    if count >= budget:
        break
    for i in range(16 ** (2 * n)):
        if count >= budget:
            break
        s = format(i, f"0{2*n}x")
        print(s)
        count += 1
PY
}

blind_gen_ascii_tokens() {
  local block
  block="$(blind_req_hint probe_block)"
  python3 - "$BLIND_ASCII_BUDGET" "${block:-0}" <<'PY'
import itertools
import sys
budget = int(sys.argv[1])
block = int(sys.argv[2])
chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
lengths = range(block, 3 * block + 1, block) if block else range(1, 6)
count = 0
for n in lengths:
    if count >= budget:
        break
    for tup in itertools.product(chars, repeat=n):
        if count >= budget:
            break
        print("".join(tup))
        count += 1
PY
}

blind_gen_ipv4_ascii() {
  python3 - "$BLIND_ASCII_BUDGET" <<'PY'
import sys
budget = int(sys.argv[1])
count = 0
for a in range(256):
    for b in range(256):
        if count >= budget:
            break
        print(f"{a}.{b}.0.0 0")
        count += 1
        if count >= budget:
            break
        print(f"255.255.255.{a} 0")
        count += 1
PY
}

blind_gen_probes() {
  case "${RELATION:-}" in
    involution) blind_gen_u32 ;;
    round_trip)
      case "${WIRE:-}" in
        hex) blind_gen_hex_bytes ;;
        ascii) blind_gen_ascii_tokens ;;
        *) blind_gen_utf8_decimal ;;
      esac
      ;;
    flow_composition) blind_gen_flow_triples ;;
    range_coverage) blind_gen_seeds_256 ;;
    cmp_order) blind_gen_cmp_pairs ;;
    value_oracle)
      case "${WIRE:-}" in
        hex) blind_gen_hex_bytes ;;
        ascii)
          if [[ "$(blind_req_hint probe_style)" == ipv4 ]]; then
            blind_gen_ipv4_ascii
          else
            blind_gen_ascii_tokens
          fi
          ;;
        *) blind_gen_hex_bytes ;;
      esac
      ;;
    *)
      echo "blind-gen: unsupported relation=${RELATION:-}" >&2
      return 1
      ;;
  esac
}
