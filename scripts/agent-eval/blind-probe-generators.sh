#!/usr/bin/env bash
# G73 blind probe generators. Use only .req fields (relation, domain, wire, max_total).
# No CASE.md witnesses, no timeline reject lines, no hand PROBES=.

BLIND_BYTE_BUDGET="${METAMORPHIC_BLIND_BYTE:-256}"
BLIND_FLOW_BUDGET="${METAMORPHIC_BLIND_FLOW:-64}"
BLIND_U32_BUDGET="${METAMORPHIC_BLIND_U32:-256}"
BLIND_ASCII_BUDGET="${METAMORPHIC_BLIND_ASCII:-256}"
BLIND_HEX_BUDGET="${METAMORPHIC_BLIND_HEX:-256}"

blind_flow_nm() {
  case "${DOMAIN:-}" in
    zig_wyhash) printf '%s %s' 48 10 ;;
    go_base64_streaming) printf '%s %s' 4 2 ;;
    rust_crc32fast_combine) printf '%s %s' 0 0 ;;
    ca_flow90) printf '%s %s' 1 2 ;;
    *) printf '%s %s' 1 1 ;;
  esac
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
  local i j max=3
  [[ "${DOMAIN:-}" == llvm_bolt_cmp ]] || max=1
  for ((i = 0; i <= max; i++)); do
    for ((j = 0; j <= max; j++)); do
      printf '%s %s\n' "$i" "$j"
    done
  done
}

blind_gen_flow_triples() {
  local n m seed start=0
  read -r n m <<<"$(blind_flow_nm)"
  [[ "${DOMAIN:-}" == go_base64_streaming ]] && start=1
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
  python3 - "$BLIND_ASCII_BUDGET" <<'PY'
import itertools
import sys
budget = int(sys.argv[1])
chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
count = 0
for n in range(1, 6):
    if count >= budget:
        break
    for tup in itertools.product(chars, repeat=n):
        if count >= budget:
            break
        print("".join(tup))
        count += 1
PY
}

blind_gen_parseip_ascii() {
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
          if [[ "${DOMAIN:-}" == cosmo_parseip ]]; then
            blind_gen_parseip_ascii
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
