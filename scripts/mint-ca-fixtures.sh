#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Mints the two Route B CA specimens. Compiler output, not hand bytes.
# Run once locally to (re)generate the committed .ngb. CI never recompiles.
# Needs docker (pinned gcc image) to produce a Linux x86_64 ELF off-Linux.

CA="fixtures/ca"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-ca: need docker" >&2; exit 1; }

docker run --rm --platform linux/amd64 -v "$ROOT/$CA:/w" -w /w "$IMG" sh -c "
  gcc -O0 $FLAGS -o ca_rule30_v1.elf ca_rule30.c &&
  gcc -O2 $FLAGS -fno-tree-loop-distribute-patterns -o ca_rule30_v2.elf ca_rule30.c &&
  gcc -O0 $FLAGS -DRULE=90 -o ca_rule30_wrongrule.elf ca_rule30.c
"

make -C tools -s bin/ngb-pack bin/ngb-parse bin/ca-rule30-fixture bin/ca-rule30-patch-fixture >/dev/null
tools/bin/ca-rule30-fixture "$CA/ca_rule30_v1.elf" "$CA/ca_rule30_v1.ngb"
tools/bin/ca-rule30-fixture "$CA/ca_rule30_v2.elf" "$CA/ca_rule30_v2.ngb"
tools/bin/ngb-pack "$CA/ca_rule30_wrongrule.elf" "$CA/ca_rule30_wrongrule.ngb"
NANOGRAPH_ROOT="$ROOT" tools/bin/ca-rule30-patch-fixture

h1="$(tools/bin/ngb-parse "$CA/ca_rule30_v1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$CA/ca_rule30_v2.ngb" | sed -n 's/.*graph_root_hash=//p')"
[[ "$h1" != "$h2" ]] || { echo "mint-ca: variants share a hash; not structurally distinct" >&2; exit 1; }

rm -f "$CA/ca_rule30_v1.elf" "$CA/ca_rule30_v2.elf" "$CA/ca_rule30_wrongrule.elf"
echo "minted v1=$h1 v2=$h2 wrongrule=$(tools/bin/ngb-parse "$CA/ca_rule30_wrongrule.ngb" | sed -n 's/.*graph_root_hash=//p')"
