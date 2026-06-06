#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Mints Route B CA specimens. Compiler output, not hand bytes.
# Run once locally to (re)generate committed .ngb. CI never recompiles.
# Needs docker (pinned gcc image) to produce Linux x86_64 ELFs off-Linux.

CA="fixtures/ca"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

# rule width gens init wrong
SPECS=(
  "30 31 16 center 90"
  "50 31 16 center 90"
  "110 96 96 right 90"
)

command -v docker >/dev/null 2>&1 || { echo "mint-ca: need docker" >&2; exit 1; }
[[ -f "$CA/ca_eca.c" ]] || { echo "mint-ca: missing $CA/ca_eca.c" >&2; exit 1; }

mint_goldens() {
  python3 - "${SPECS[@]}" <<'PY'
import sys
for spec in sys.argv[1:]:
    rule, width, gens, init, _wrong = spec.split()
    rule, width, gens = int(rule), int(width), int(gens)
    cur = [0] * width
    cur[width - 1 if init == "right" else width // 2] = 1
    rows = []
    for _ in range(gens):
        rows.append("".join("#" if x else "." for x in cur))
        nxt = [0] * width
        for i in range(width):
            l = cur[i - 1] if i > 0 else 0
            c = cur[i]
            r = cur[i + 1] if i < width - 1 else 0
            nxt[i] = (rule >> ((l << 2) | (c << 1) | r)) & 1
        cur = nxt
    open(f"fixtures/ca/rule{rule}.golden", "w").write("\n".join(rows) + "\n")
    print("golden", f"rule{rule}", f"{width}x{gens}", init)
PY
}

defs() {
  local rule="$1" width="$2" gens="$3" init="$4"
  local d="-DRULE=$rule -DWIDTH=$width -DGENS=$gens"
  [[ "$init" == "right" ]] && d="$d -DINIT_RIGHT"
  printf '%s' "$d"
}

make -C tools -s bin/ngb-pack bin/ngb-parse bin/ca-rule30-fixture bin/ca-rule30-patch-fixture >/dev/null
mint_goldens

for spec in "${SPECS[@]}"; do
  read -r rule width gens init wrong <<<"$spec"
  d_v="$(defs "$rule" "$width" "$gens" "$init")"
  d_w="$(defs "$wrong" "$width" "$gens" "$init")"
  docker run --rm --platform linux/amd64 -v "$ROOT/$CA:/w" -w /w "$IMG" sh -c "
    gcc -O0 $FLAGS $d_v -o ca_rule${rule}_v1.elf ca_eca.c &&
    gcc -O2 $FLAGS -fno-tree-loop-distribute-patterns $d_v -o ca_rule${rule}_v2.elf ca_eca.c &&
    gcc -O0 $FLAGS $d_w -o ca_rule${rule}_wrongrule.elf ca_eca.c
  "

  if [[ "$rule" == "30" ]]; then
    tools/bin/ca-rule30-fixture "$CA/ca_rule30_v1.elf" "$CA/ca_rule30_v1.ngb"
    tools/bin/ca-rule30-fixture "$CA/ca_rule30_v2.elf" "$CA/ca_rule30_v2.ngb"
    NANOGRAPH_ROOT="$ROOT" tools/bin/ca-rule30-patch-fixture
  else
    tools/bin/ngb-pack "$CA/ca_rule${rule}_v1.elf" "$CA/ca_rule${rule}_v1.ngb"
    tools/bin/ngb-pack "$CA/ca_rule${rule}_v2.elf" "$CA/ca_rule${rule}_v2.ngb"
  fi
  tools/bin/ngb-pack "$CA/ca_rule${rule}_wrongrule.elf" "$CA/ca_rule${rule}_wrongrule.ngb"
  rm -f "$CA/ca_rule${rule}_v1.elf" "$CA/ca_rule${rule}_v2.elf" "$CA/ca_rule${rule}_wrongrule.elf"

  h1="$(tools/bin/ngb-parse "$CA/ca_rule${rule}_v1.ngb" | sed -n 's/.*graph_root_hash=//p')"
  h2="$(tools/bin/ngb-parse "$CA/ca_rule${rule}_v2.ngb" | sed -n 's/.*graph_root_hash=//p')"
  [[ "$h1" != "$h2" ]] || { echo "mint-ca: rule $rule variants share hash" >&2; exit 1; }
  echo "rule${rule} v1=${h1:0:12} v2=${h2:0:12}"
done

echo "mint-ca-fixtures OK"
