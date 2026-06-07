#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IM="fixtures/input-math"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-input-math: need docker" >&2; exit 1; }
[[ -f "$IM/gcd.c" ]] || { echo "mint-input-math: missing $IM/gcd.c" >&2; exit 1; }

make -C tools -s bin/ngb-pack bin/ngb-parse >/dev/null

docker run --rm --platform linux/amd64 -v "$ROOT/$IM:/w" -w /w "$IMG" sh -c "
  gcc -O0 $FLAGS -o gcd_v1.elf gcd.c &&
  gcc -O2 $FLAGS -fno-tree-loop-distribute-patterns -o gcd_v2.elf gcd.c &&
  gcc -O0 $FLAGS -DNEARMISS_GCD -o gcd_nearmiss.elf gcd.c &&
  gcc -O0 $FLAGS -DEVIL_GCD -o gcd_evil.elf gcd.c
"

tools/bin/ngb-pack "$IM/gcd_v1.elf" "$IM/gcd_v1.ngb"
tools/bin/ngb-pack "$IM/gcd_v2.elf" "$IM/gcd_v2.ngb"
tools/bin/ngb-pack "$IM/gcd_nearmiss.elf" "$IM/gcd_nearmiss.ngb"
tools/bin/ngb-pack "$IM/gcd_evil.elf" "$IM/gcd_evil.ngb"
rm -f "$IM/gcd_v1.elf" "$IM/gcd_v2.elf" "$IM/gcd_nearmiss.elf" "$IM/gcd_evil.elf"

h1="$(tools/bin/ngb-parse "$IM/gcd_v1.ngb" | sed -n 's/.*graph_root_hash=//p')"
h2="$(tools/bin/ngb-parse "$IM/gcd_v2.ngb" | sed -n 's/.*graph_root_hash=//p')"
[[ "$h1" != "$h2" ]] || { echo "mint-input-math: v1/v2 share hash" >&2; exit 1; }
echo "gcd v1=${h1:0:12} v2=${h2:0:12}"
echo "mint-input-math-fixtures OK"
