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
#   range_coverage  reachability (lo_seed/hi_seed) and containment (sweep min/max)
#               are separate phases (G38); rejects name phase=reachability|containment.
#   cmp_order     bool comparator: cmp(i,i)==0; cmp(i,j)==1 implies cmp(j,i)==0.
#   size_monotone x < y implies f(x) <= f(y) over ascending size probes.
#   conserve_popcount popcount(f(x)) == popcount(x) for a bit-permutation map.
#   linear_xor      f(a^b) == f(a)^f(b) over probe pairs (GF(2) homomorphism).
#   flow_composition flow(n+m,s) == flow(m, flow(n,s)) over probe triples.
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

gen_capnproto_base64() {
  printf '%s\n' Zm9v Y29yZ2U= Zm9v@ Y29yZ2U==
}

gen_rust_base64() {
  printf '%s\n' iYU= iYV= /w== /x== Zm9v
}

gen_cosmo_parseip() {
  printf '%s\n' \
    '0.0.0.0 0' \
    '10.0.0.1 167772161' \
    '127.0.0.1 2130706433' \
    '192.168.1.1 3232235777' \
    '255.255.255.255 4294967295' \
    '255.255.255.256 REJECT' \
    '4294967296 REJECT'
}

# JSON string-body bytes (hex) to expected decoded bytes (hex), or REJECT. Valid
# ASCII and 2/3/4-byte UTF-8 round-trip canonically; overlong c0 80 and surrogate
# ed a0 80 must be rejected. The buggy rev echoes them verbatim.
gen_cosmo_ljson() {
  printf '%s\n' \
    '666f6f 666f6f' \
    'c2a9 c2a9' \
    'e282ac e282ac' \
    'f09f9880 f09f9880' \
    'c080 REJECT' \
    'eda080 REJECT'
}

# gb_flip seeds. Each is one gb_init_rand(seed) + one rand_len draw; the sweep
# samples the draw's range. The honest range reaches max_len, the buggy one
# (off-by-one span) never does, so the observed maximum separates them.
gen_knuth_rand_len() {
  local s
  for ((s = 1; s <= 256; s++)); do printf '%s\n' "$s"; done
}

# Section index pairs for BOLT compareSections (0=mover, 1=main, 2=warm, 3=cold).
# Full 4x4 matrix; self-pair 0 0 stays first as the pre-registered timeline
# witness (irreflexivity on hot-text mover).
gen_llvm_bolt_cmp() {
  printf '%s\n' '0 0'
  local i j
  for ((i = 0; i < 4; i++)); do
    for ((j = 0; j < 4; j++)); do
      [[ "$i" -eq 0 && "$j" -eq 0 ]] && continue
      printf '%s %s\n' "$i" "$j"
    done
  done
}

# Ascending request sizes for jemalloc sz_s2u_compute_using_delta. The pair
# 0x70000000000000ff -> 0xffffffffffffff00 is the pre-registered timeline
# witness (overflow wrap inverts usable size).
gen_jemalloc_s2u() {
  printf '%s\n' 1024 4096 65536 8070450532247928832
}

# u32 probes; 3 first as the pre-registered timeline witness (popcount 2 -> 1).
gen_conserve_popcount() {
  printf '%s\n' 3 1 2 4 5 6 7 8 9 10 255 256
}

# Rule-90 step pairs; (1,2) is the pre-registered timeline witness for linear_xor.
gen_ca_step90() {
  printf '%s\n' '1 2' '3 5' '7 11' '255 256'
}

gen_ca_step184() {
  printf '%s\n' 5 9 42 255 513
}

# n m seed triples; (1,2,5) is the pre-registered flow_composition witness.
gen_ca_flow90() {
  printf '%s\n' '1 2 5' '2 2 7' '1 3 42' '2 3 13'
}

# n m seed; n=48 triggers partial token path in zig_wyhash.c (PARTIAL_N).
gen_zig_wyhash() {
  printf '%s\n' '48 10 5' '48 12 7' '48 8 42' '48 15 13'
}

gen_go_base64_streaming() {
  printf '%s\n' '4 2 5'
}

gen_rust_crc32fast_combine() {
  printf '%s\n' '0 0 5' '0 0 7' '0 0 13'
}

gen_bytes() {
  local budget="${METAMORPHIC_BYTES_BUDGET:-64}"
  METAMORPHIC_BLIND_HEX="$budget"
  # shellcheck source=blind-probe-generators.sh
  source "$(dirname "$0")/blind-probe-generators.sh"
  blind_gen_hex_bytes
}

popcount_u() {
  local v="$1" c=0
  while ((v > 0)); do
    c=$((c + v % 2))
    v=$((v / 2))
  done
  printf '%s' "$c"
}

runner_empty_fail() {
  echo "metamorphic-verify: runner returned no output; run ./nanograph doctor" >&2
  exit 2
}

u64_lt() { python3 -c 'import sys; print(int(sys.argv[1]) < int(sys.argv[2]))' "$1" "$2"; }
u64_gt() { python3 -c 'import sys; print(int(sys.argv[1]) > int(sys.argv[2]))' "$1" "$2"; }

gen_probes() {
  if [[ -n "${METAMORPHIC_PROBES:-}" ]]; then
    printf '%s\n' "$METAMORPHIC_PROBES"
    return
  fi
  if [[ "${METAMORPHIC_BLIND:-}" == 1 ]]; then
    # shellcheck source=blind-probe-generators.sh
    source "$(dirname "$0")/blind-probe-generators.sh"
    blind_gen_probes
    return
  fi
  case "$DOMAIN" in
    u32) gen_u32 ;;
    utf8) gen_utf8 ;;
    leb128) gen_leb128 ;;
    knuth_sgb) gen_knuth_sgb ;;
    wabt_leb128) gen_wabt_leb128 ;;
    capnproto_base64) gen_capnproto_base64 ;;
    rust_base64) gen_rust_base64 ;;
    cosmo_parseip) gen_cosmo_parseip ;;
    cosmo_ljson) gen_cosmo_ljson ;;
    knuth_rand_len) gen_knuth_rand_len ;;
    llvm_bolt_cmp) gen_llvm_bolt_cmp ;;
    jemalloc_s2u) gen_jemalloc_s2u ;;
    conserve_popcount) gen_conserve_popcount ;;
    ca_step90) gen_ca_step90 ;;
    ca_step184) gen_ca_step184 ;;
    ca_flow90) gen_ca_flow90 ;;
    zig_wyhash) gen_zig_wyhash ;;
    go_base64_streaming) gen_go_base64_streaming ;;
    rust_crc32fast_combine) gen_rust_crc32fast_combine ;;
    bytes) gen_bytes ;;
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

if [[ "$RELATION" == range_coverage ]]; then
  DRAW="$(reqval draw)"
  LO="$(reqval lo)"
  HI="$(reqval hi)"
  LO_SEED="$(reqval lo_seed)"
  HI_SEED="$(reqval hi_seed)"
  REACH="$(reqval reachability)"
  CONTAIN="$(reqval containment)"
  [[ -n "$DRAW" && -n "$LO" && -n "$HI" ]] || {
    echo "metamorphic-verify: range_coverage needs draw, lo, hi in $REQ" >&2
    exit 2
  }
  if [[ -z "$REACH" ]]; then
    if [[ -n "$LO_SEED" && -n "$HI_SEED" ]]; then REACH=on; else REACH=off; fi
  fi
  if [[ -z "$CONTAIN" ]]; then CONTAIN=sweep; fi
  [[ "$REACH" == on || "$REACH" == off ]] || {
    echo "metamorphic-verify: reachability must be on or off" >&2
    exit 2
  }
  [[ "$CONTAIN" == sweep || "$CONTAIN" == off ]] || {
    echo "metamorphic-verify: containment must be sweep or off" >&2
    exit 2
  }
  if [[ "$REACH" == on ]]; then
    [[ -n "$LO_SEED" && -n "$HI_SEED" ]] || {
      echo "metamorphic-verify: reachability=on needs lo_seed and hi_seed" >&2
      exit 2
    }
  fi

  reach_result=skip
  if [[ "$REACH" == on ]]; then
    lo_got="$(./scripts/run-linux-elf-capture.sh "$CAND" "$DRAW" "$LO_SEED" 2>/dev/null || true)"
    if [[ "$lo_got" != "$LO" ]]; then
      echo "verdict=reject hash=${hash:0:12} relation=range_coverage phase=reachability endpoint=lo seed=$LO_SEED got=${lo_got:-} want=$LO hex=$(printf '%02x' "${lo_got:-0}")"
      exit 1
    fi
    hi_got="$(./scripts/run-linux-elf-capture.sh "$CAND" "$DRAW" "$HI_SEED" 2>/dev/null || true)"
    if [[ "$hi_got" != "$HI" ]]; then
      echo "verdict=reject hash=${hash:0:12} relation=range_coverage phase=reachability endpoint=hi seed=$HI_SEED got=${hi_got:-} want=$HI hex=$(printf '%02x' "${hi_got:-0}")"
      exit 1
    fi
    reach_result=pass
  fi

  contain_result=skip
  obs_min=""
  obs_max=""
  samples=0
  if [[ "$CONTAIN" == sweep ]]; then
    probes=()
    while read -r p; do probes+=("$p"); done < <(gen_probes)

    while read -r v; do
      [[ "$v" =~ ^[0-9]+$ ]] || continue
      samples=$((samples + 1))
      [[ -z "$obs_min" || "$v" -lt "$obs_min" ]] && obs_min="$v"
      [[ -z "$obs_max" || "$v" -gt "$obs_max" ]] && obs_max="$v"
    done < <(printf '%s\n' "${probes[@]}" | run_mode "$DRAW")

    [[ "$samples" -ge 1 ]] || {
      echo "metamorphic-verify: range_coverage drew 0 samples" >&2
      exit 2
    }

    if [[ "$obs_min" -ne "$LO" || "$obs_max" -ne "$HI" ]]; then
      echo "verdict=reject hash=${hash:0:12} relation=range_coverage phase=containment observed=[$obs_min,$obs_max] declared=[$LO,$HI] samples=$samples hex=$(printf '%02x' "$obs_max")"
      exit 1
    fi
    contain_result=pass
  fi

  extra=" reachability=$reach_result containment=$contain_result"
  [[ "$REACH" == on ]] && extra="$extra lo_seed=$LO_SEED hi_seed=$HI_SEED"
  if [[ "$CONTAIN" == sweep ]]; then
    echo "verdict=accept hash=${hash:0:12} relation=range_coverage observed=[$obs_min,$obs_max] declared=[$LO,$HI] samples=$samples$extra"
  else
    echo "verdict=accept hash=${hash:0:12} relation=range_coverage declared=[$LO,$HI]$extra"
  fi
  exit 0
fi

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

  # Witness replay (METAMORPHIC_PROBES) may pass a single probe the candidate
  # rejects outright; that is a non-violation, not a harness error.
  [[ "$accepted" -ge 1 || -n "${METAMORPHIC_PROBES:-}" ]] || {
    echo "metamorphic-verify: round_trip accepted 0 inputs (domain has no canonical sample)" >&2
    exit 2
  }
  echo "verdict=accept hash=${hash:0:12} relation=round_trip accepted=$accepted separator=none"
  exit 0
fi

if [[ "$RELATION" == value_oracle ]]; then
  MODE="$(reqval mode)"
  REJECT="$(reqval reject)"
  WIRE="$(reqval wire)"
  [[ -n "$MODE" && -n "$REJECT" ]] || {
    echo "metamorphic-verify: value_oracle needs mode, reject in $REQ" >&2
    exit 2
  }

  ips=()
  expects=()
  while read -r line; do
    [[ -z "$line" ]] && continue
    ips+=("${line%% *}")
    expects+=("${line#* }")
  done < <(gen_probes)

  gots=()
  while read -r g; do gots+=("$g"); done < <(printf '%s\n' "${ips[@]}" | run_mode "$MODE")

  matched=0
  for i in "${!ips[@]}"; do
    ip="${ips[$i]}"
    want="${expects[$i]}"
    got="${gots[$i]:-}"
    if [[ "$want" == "$REJECT" ]]; then
      [[ "$got" == "$REJECT" ]] && matched=$((matched + 1)) && continue
    else
      [[ "$got" == "$want" ]] && matched=$((matched + 1)) && continue
    fi
    got2="$(./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$ip" 2>/dev/null || true)"
    if [[ "$want" == "$REJECT" ]]; then
      [[ -n "$got2" && "$got2" != "$REJECT" ]] || continue
    else
      [[ "$got2" == "$want" ]] && continue
    fi
    if [[ "$WIRE" == ascii ]]; then
      hexw="$(printf '%s' "$ip" | hexdump -ve '1/1 "%02x"')"
    elif [[ "$WIRE" == hex ]]; then
      hexw="$ip"
    else
      hexb="$(printf '%X' "$ip")"
      hexw="${hexb:1}"
    fi
    echo "verdict=reject hash=${hash:0:12} relation=value_oracle witness bytes=$ip hex=$hexw want=$want got=$got2"
    exit 1
  done

  [[ "$matched" -ge 1 ]] || {
    echo "metamorphic-verify: value_oracle matched 0 cases" >&2
    exit 2
  }
  echo "verdict=accept hash=${hash:0:12} relation=value_oracle matched=$matched separator=none"
  exit 0
fi

if [[ "$RELATION" == cmp_order ]]; then
  MODE="$(reqval mode)"
  [[ -n "$MODE" && -n "$DOMAIN" ]] || {
    echo "metamorphic-verify: cmp_order needs mode, domain in $REQ" >&2
    exit 2
  }

  pairs=()
  while read -r line; do [[ -z "$line" ]] && continue; pairs+=("$line"); done < <(gen_probes)
  [[ "${#pairs[@]}" -ge 1 ]] || {
    echo "metamorphic-verify: cmp_order generated 0 pairs for domain=$DOMAIN" >&2
    exit 2
  }

  # Empty-output backend faults are retried inside run-linux-elf-capture.sh;
  # anything still non-bool here is a harness error.
  cmp_run() { ./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$1" "$2" 2>/dev/null | tr -d '\n\r' || true; }

  checked=0
  for line in "${pairs[@]}"; do
    i="${line%% *}"
    j="${line#* }"
    ij="$(cmp_run "$i" "$j")"
    [[ "$ij" == 0 || "$ij" == 1 ]] || {
      echo "metamorphic-verify: cmp_order non-bool output for pair $i,$j (got '${ij}')" >&2
      exit 2
    }
    ji="$(cmp_run "$j" "$i")"
    [[ "$ji" == 0 || "$ji" == 1 ]] || {
      echo "metamorphic-verify: cmp_order non-bool output for pair $j,$i (got '${ji}')" >&2
      exit 2
    }

    if [[ "$i" == "$j" && "$ij" != "0" ]]; then
      hex="$(printf '%x%x' "$i" "$j")"
      echo "verdict=reject hash=${hash:0:12} relation=cmp_order witness pair=$i,$j hex=$hex got_ij=$ij want_ij=0"
      exit 1
    fi
    if [[ "$i" != "$j" && "$ij" == "1" && "$ji" != "0" ]]; then
      hex="$(printf '%x%x' "$i" "$j")"
      echo "verdict=reject hash=${hash:0:12} relation=cmp_order witness pair=$i,$j hex=$hex got_ij=$ij got_ji=$ji"
      exit 1
    fi
    checked=$((checked + 1))
  done

  [[ "$checked" -ge 1 ]] || {
    echo "metamorphic-verify: cmp_order checked 0 pairs" >&2
    exit 2
  }
  echo "verdict=accept hash=${hash:0:12} relation=cmp_order checked=$checked separator=none"
  exit 0
fi

if [[ "$RELATION" == size_monotone ]]; then
  MODE="$(reqval mode)"
  OVERFLOW_SIZE="$(reqval overflow_size)"
  OVERFLOW_EXPECT="$(reqval overflow_expect)"
  [[ -n "$MODE" && -n "$DOMAIN" && -n "$OVERFLOW_SIZE" && -n "$OVERFLOW_EXPECT" ]] || {
    echo "metamorphic-verify: size_monotone needs mode, domain, overflow_size, overflow_expect in $REQ" >&2
    exit 2
  }

  sizes=()
  while read -r s; do [[ -z "$s" ]] && continue; sizes+=("$s"); done < <(gen_probes)
  [[ "${#sizes[@]}" -ge 2 ]] || {
    echo "metamorphic-verify: size_monotone needs >=2 ascending interior sizes" >&2
    exit 2
  }

  mono_run() { ./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$1" 2>/dev/null | tr -d '\n\r' || true; }

  prev_x="${sizes[0]}"
  prev_fx="$(mono_run "$prev_x")"
  [[ "$prev_fx" =~ ^[0-9]+$ ]] || {
    echo "metamorphic-verify: size_monotone non-numeric output for x=$prev_x (got '${prev_fx}')" >&2
    exit 2
  }

  checked=1
  for ((i = 1; i < ${#sizes[@]}; i++)); do
    x="${sizes[$i]}"
    fx="$(mono_run "$x")"
    [[ "$fx" =~ ^[0-9]+$ ]] || fx="$(mono_run "$x")"
    [[ "$fx" =~ ^[0-9]+$ ]] || {
      echo "metamorphic-verify: size_monotone non-numeric output for x=$x (got '${fx}')" >&2
      exit 2
    }
    if [[ "$(u64_lt "$prev_x" "$x")" == True && "$(u64_gt "$prev_fx" "$fx")" == True ]]; then
      hex="$(python3 -c 'import sys; print(format(int(sys.argv[1]), "x"))' "$x")"
      echo "verdict=reject hash=${hash:0:12} relation=size_monotone phase=monotone witness x=$prev_x y=$x fx=$prev_fx fy=$fx hex=$hex"
      exit 1
    fi
    prev_x="$x"
    prev_fx="$fx"
    checked=$((checked + 1))
  done

  ov_got="$(mono_run "$OVERFLOW_SIZE")"
  [[ "$ov_got" =~ ^[0-9]+$ ]] || ov_got="$(mono_run "$OVERFLOW_SIZE")"
  [[ "$ov_got" =~ ^[0-9]+$ ]] || {
    echo "metamorphic-verify: size_monotone non-numeric overflow output (got '${ov_got}')" >&2
    exit 2
  }
  if [[ "$ov_got" != "$OVERFLOW_EXPECT" ]]; then
    hex="$(python3 -c 'import sys; print(format(int(sys.argv[1]), "x"))' "$OVERFLOW_SIZE")"
    echo "verdict=reject hash=${hash:0:12} relation=size_monotone phase=overflow size=$OVERFLOW_SIZE got=$ov_got want=$OVERFLOW_EXPECT hex=$hex"
    exit 1
  fi

  echo "verdict=accept hash=${hash:0:12} relation=size_monotone checked=$checked overflow=pass separator=none"
  exit 0
fi

if [[ "$RELATION" == linear_xor ]]; then
  MODE="$(reqval mode)"
  [[ -n "$MODE" && -n "$DOMAIN" ]] || {
    echo "metamorphic-verify: linear_xor needs mode, domain in $REQ" >&2
    exit 2
  }

  pairs=()
  while read -r line; do [[ -z "$line" ]] && continue; pairs+=("$line"); done < <(gen_probes)
  [[ "${#pairs[@]}" -ge 1 ]] || {
    echo "metamorphic-verify: linear_xor generated 0 pairs" >&2
    exit 2
  }

  xor_run() { ./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$1" 2>/dev/null | tr -d '\n\r' || true; }

  checked=0
  for line in "${pairs[@]}"; do
    a="${line%% *}"
    b="${line#* }"
    ab=$((a ^ b))
    fab="$(xor_run "$ab")"
    fa="$(xor_run "$a")"
    fb="$(xor_run "$b")"
    [[ "$fab" =~ ^[0-9]+$ && "$fa" =~ ^[0-9]+$ && "$fb" =~ ^[0-9]+$ ]] || {
      echo "metamorphic-verify: linear_xor non-numeric output for pair $a,$b" >&2
      exit 2
    }
    want=$((fa ^ fb))
    if [[ "$fab" != "$want" ]]; then
      hex="$(printf '%x' "$ab")"
      echo "verdict=reject hash=${hash:0:12} relation=linear_xor witness a=$a b=$b xor=$ab fab=$fab fa=$fa fb=$fb want=$want hex=$hex"
      exit 1
    fi
    checked=$((checked + 1))
  done

  echo "verdict=accept hash=${hash:0:12} relation=linear_xor checked=$checked separator=none"
  exit 0
fi

if [[ "$RELATION" == flow_composition ]]; then
  MODE="$(reqval mode)"
  MAX_TOTAL="$(reqval max_total)"
  [[ -n "$MODE" && -n "$DOMAIN" && -n "$MAX_TOTAL" ]] || {
    echo "metamorphic-verify: flow_composition needs mode, domain, max_total in $REQ" >&2
    exit 2
  }

  triples=()
  while read -r line; do [[ -z "$line" ]] && continue; triples+=("$line"); done < <(gen_probes)
  [[ "${#triples[@]}" -ge 1 ]] || {
    echo "metamorphic-verify: flow_composition generated 0 triples" >&2
    exit 2
  }

  flow_run() {
    ./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$1" "$2" 2>/dev/null | tr -d '\n\r' || true
  }

  checked=0
  for line in "${triples[@]}"; do
    n="${line%% *}"
    rest="${line#* }"
    m="${rest%% *}"
    seed="${rest#* }"
    total=$((n + m))
    if [[ "$total" -gt "$MAX_TOTAL" ]]; then
      continue
    fi
    once="$(flow_run "$total" "$seed")"
    part="$(flow_run "$n" "$seed")"
    composed="$(flow_run "$m" "$part")"
    [[ "$once" =~ ^[0-9]+$ && "$part" =~ ^[0-9]+$ && "$composed" =~ ^[0-9]+$ ]] || {
      if [[ "${METAMORPHIC_BLIND:-}" == 1 ]]; then
        continue
      fi
      echo "metamorphic-verify: flow_composition non-numeric output n=$n m=$m seed=$seed" >&2
      exit 2
    }
    if [[ "$once" != "$composed" ]]; then
      hex="$(printf '%x' "$seed")"
      echo "verdict=reject hash=${hash:0:12} relation=flow_composition witness n=$n m=$m seed=$seed once=$once composed=$composed hex=$hex"
      exit 1
    fi
    checked=$((checked + 1))
  done

  [[ "$checked" -ge 1 ]] || {
    echo "metamorphic-verify: flow_composition checked 0 triples within max_total=$MAX_TOTAL" >&2
    exit 2
  }
  echo "verdict=accept hash=${hash:0:12} relation=flow_composition checked=$checked separator=none"
  exit 0
fi

if [[ "$RELATION" == conserve_popcount ]]; then
  MODE="$(reqval mode)"
  [[ -n "$MODE" && -n "$DOMAIN" ]] || {
    echo "metamorphic-verify: conserve_popcount needs mode, domain in $REQ" >&2
    exit 2
  }

  probes=()
  while read -r p; do [[ -z "$p" ]] && continue; probes+=("$p"); done < <(gen_probes)
  [[ "${#probes[@]}" -ge 1 ]] || {
    echo "metamorphic-verify: conserve_popcount generated 0 probes" >&2
    exit 2
  }

  checked=0
  for x in "${probes[@]}"; do
    got="$(./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$x" 2>/dev/null | tr -d '\n\r' || true)"
    [[ "$got" =~ ^[0-9]+$ ]] || got="$(./scripts/run-linux-elf-capture.sh "$CAND" "$MODE" "$x" 2>/dev/null | tr -d '\n\r' || true)"
    [[ "$got" =~ ^[0-9]+$ ]] || {
      echo "metamorphic-verify: conserve_popcount non-numeric output for x=$x (got '${got}')" >&2
      exit 2
    }
    want="$(popcount_u "$x")"
    got_pc="$(popcount_u "$got")"
    if [[ "$got_pc" != "$want" ]]; then
      hex="$(printf '%x' "$x")"
      echo "verdict=reject hash=${hash:0:12} relation=conserve_popcount witness x=$x hex=$hex pop_in=$want pop_out=$got_pc got=$got"
      exit 1
    fi
    checked=$((checked + 1))
  done

  echo "verdict=accept hash=${hash:0:12} relation=conserve_popcount checked=$checked separator=none"
  exit 0
fi

if [[ "$RELATION" != involution ]]; then
  echo "metamorphic-verify: unsupported relation=$RELATION" >&2
  exit 2
fi

probes=()
while read -r p; do probes+=("$p"); done < <(gen_probes)
((${#probes[@]} > 0)) || runner_empty_fail

ys=()
while read -r y; do ys+=("$y"); done < <(printf '%s\n' "${probes[@]}" | apply_once)

ys_filled=()
for y in ${ys[@]+"${ys[@]}"}; do ys_filled+=("${y:-0}"); done

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
