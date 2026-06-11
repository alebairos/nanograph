#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

srcdir="${1:-}"
wyhash_src="${2:-}"
out="${3:-}"
[[ -n "$srcdir" && -n "$wyhash_src" && -n "$out" ]] || {
  echo "usage: mint-one-zig.sh <srcdir> <wyhash.zig> <out.ngb>" >&2
  exit 1
}
[[ -f "$srcdir/main.zig" ]] || { echo "mint-one-zig: missing $srcdir/main.zig" >&2; exit 1; }
[[ -f "$wyhash_src" ]] || { echo "mint-one-zig: missing $wyhash_src" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || { echo "mint-one-zig: need docker" >&2; exit 1; }
make -C tools -s bin/ngb-pack >/dev/null

SRCDIR="$(cd "$srcdir" && pwd)"
cp "$wyhash_src" "$SRCDIR/wyhash_impl.zig"

docker run --rm --platform linux/amd64 -v "$SRCDIR:/w" -w /w ubuntu:24.04 \
  sh -c 'apt-get update -qq && apt-get install -y -qq curl xz-utils >/dev/null && \
    curl -sL https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz | tar -xJ -C /usr/local && \
    /usr/local/zig-linux-x86_64-0.13.0/zig build-exe -target x86_64-linux-gnu -O ReleaseSmall -fno-strip \
      -femit-bin=__one.elf main.zig'

tools/bin/ngb-pack "$SRCDIR/__one.elf" "$out"
rm -f "$SRCDIR/__one.elf" "$SRCDIR/wyhash_impl.zig"

echo "mint-one-zig OK $out"
