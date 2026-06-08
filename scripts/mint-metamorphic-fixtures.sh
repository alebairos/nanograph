#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MM="fixtures/metamorphic"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-metamorphic: need docker" >&2; exit 1; }
[[ -f "$MM/bswap32.c" ]] || { echo "mint-metamorphic: missing $MM/bswap32.c" >&2; exit 1; }

make -C tools -s bin/ngb-pack bin/ngb-parse >/dev/null

docker run --rm --platform linux/amd64 -v "$ROOT/$MM:/w" -w /w "$IMG" sh -c "
  gcc -O0 $FLAGS -o bswap32.elf bswap32.c &&
  gcc -O0 $FLAGS -DEVIL_BSWAP -o bswap32_evil.elf bswap32.c &&
  gcc -O0 $FLAGS -DIMPOSTER_BSWAP -o bswap32_imposter.elf bswap32.c
"

tools/bin/ngb-pack "$MM/bswap32.elf" "$MM/bswap32.ngb"
tools/bin/ngb-pack "$MM/bswap32_evil.elf" "$MM/bswap32_evil.ngb"
tools/bin/ngb-pack "$MM/bswap32_imposter.elf" "$MM/bswap32_imposter.ngb"
rm -f "$MM/bswap32.elf" "$MM/bswap32_evil.elf" "$MM/bswap32_imposter.elf"

hh="$(tools/bin/ngb-parse "$MM/bswap32.ngb" | sed -n 's/.*graph_root_hash=//p')"
he="$(tools/bin/ngb-parse "$MM/bswap32_evil.ngb" | sed -n 's/.*graph_root_hash=//p')"
hi="$(tools/bin/ngb-parse "$MM/bswap32_imposter.ngb" | sed -n 's/.*graph_root_hash=//p')"
[[ "$hh" != "$he" && "$hh" != "$hi" && "$he" != "$hi" ]] || { echo "mint-metamorphic: fixtures share a hash" >&2; exit 1; }
echo "bswap32 honest=${hh:0:12} evil=${he:0:12} imposter=${hi:0:12}"
echo "mint-metamorphic-fixtures OK"
