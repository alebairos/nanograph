#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

src="${1:-}"
out="${2:-}"
[[ -n "$src" && -n "$out" ]] || { echo "usage: mint-one-elf.sh <src.c> <out.ngb> [extra gcc flags...]" >&2; exit 1; }
[[ -f "$src" ]] || { echo "mint-one-elf: missing $src" >&2; exit 1; }
shift 2
extra="$*"

IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-one-elf: need docker" >&2; exit 1; }
make -C tools -s bin/ngb-pack >/dev/null

SRCDIR="$(cd "$(dirname "$src")" && pwd)"
SRCBASE="$(basename "$src")"

# Compile via a canonical name so the embedded STT_FILE symbol, and thus the
# graph hash, depends on source content not the incidental filename.
docker run --rm --platform linux/amd64 -v "$SRCDIR:/w" -w /w "$IMG" \
  sh -c "cp $SRCBASE __one.c && gcc -O0 $FLAGS $extra -o __one.elf __one.c"
tools/bin/ngb-pack "$SRCDIR/__one.elf" "$out"
rm -f "$SRCDIR/__one.elf" "$SRCDIR/__one.c"

echo "mint-one-elf OK $out"
