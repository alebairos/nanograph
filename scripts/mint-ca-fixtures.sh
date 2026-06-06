#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Mints Route B CA specimens. Compiler output, not hand bytes.
# Run once locally to (re)generate committed .ngb. CI never recompiles.
# Needs docker (pinned gcc image) to produce Linux x86_64 ELFs off-Linux.

CA="fixtures/ca"
SRC="$CA/ca_eca.c"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-ca: need docker" >&2; exit 1; }
[[ -f "$SRC" ]] || { echo "mint-ca: missing $SRC" >&2; exit 1; }

mint_rule() {
  local rule="$1"
  local wrong="${2:-90}"
  docker run --rm --platform linux/amd64 -v "$ROOT/$CA:/w" -w /w "$IMG" sh -c "
    gcc -O0 $FLAGS -DRULE=$rule -o ca_rule${rule}_v1.elf ca_eca.c &&
    gcc -O2 $FLAGS -fno-tree-loop-distribute-patterns -DRULE=$rule -o ca_rule${rule}_v2.elf ca_eca.c &&
    gcc -O0 $FLAGS -DRULE=$wrong -o ca_rule${rule}_wrongrule.elf ca_eca.c
  "
}

mint_goldens() {
  python3 - <<'PY'
W, G = 31, 16
for rule in (30, 50, 110):
    cur = [0] * W
    cur[W // 2] = 1
    rows = []
    for _ in range(G):
        rows.append("".join("#" if x else "." for x in cur))
        nxt = [0] * W
        for i in range(W):
            l = cur[i - 1] if i > 0 else 0
            c = cur[i]
            r = cur[i + 1] if i < W - 1 else 0
            nxt[i] = (rule >> ((l << 2) | (c << 1) | r)) & 1
        cur = nxt
    path = f"fixtures/ca/rule{rule}.golden"
    open(path, "w").write("\n".join(rows) + "\n")
    print("golden", path)
PY
}

make -C tools -s bin/ngb-pack bin/ngb-parse bin/ca-rule30-fixture bin/ca-rule30-patch-fixture >/dev/null

mint_goldens

for rule in 30 50 110; do
  mint_rule "$rule"
  if [[ "$rule" == "30" ]]; then
    tools/bin/ca-rule30-fixture "$CA/ca_rule${rule}_v1.elf" "$CA/ca_rule${rule}_v1.ngb"
    tools/bin/ca-rule30-fixture "$CA/ca_rule${rule}_v2.elf" "$CA/ca_rule${rule}_v2.ngb"
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
