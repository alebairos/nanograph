#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

src="${1:-}"
out="${2:-}"
shift 2 || true

[[ -n "$src" && -n "$out" ]] || { echo "usage: mint-one-rust.sh <src.rs> <out.ngb> [--cfg name]..." >&2; exit 1; }
[[ -f "$src" ]] || { echo "mint-one-rust: missing $src" >&2; exit 1; }

cfg_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cfg)
      [[ -n "${2:-}" ]] || { echo "mint-one-rust: --cfg needs a name" >&2; exit 1; }
      cfg_args+=(--cfg "$2")
      shift 2
      ;;
    *) echo "mint-one-rust: unknown arg $1" >&2; exit 2 ;;
  esac
done

cfg_clause=""
if ((${#cfg_args[@]})); then
  cfg_clause="${cfg_args[*]} "
fi

IMG="rust:1.79"

command -v docker >/dev/null 2>&1 || { echo "mint-one-rust: need docker" >&2; exit 1; }
make -C tools -s bin/ngb-pack >/dev/null

SRCDIR="$(cd "$(dirname "$src")" && pwd)"
SRCBASE="$(basename "$src")"

# Compile via a canonical name so the embedded source path, and thus the graph
# hash, depends on source content not the incidental filename.
docker run --rm --platform linux/amd64 -v "$SRCDIR:/w" -w /w "$IMG" \
  sh -c "cp $SRCBASE __one.rs && rustc -O --edition 2021 -C panic=abort \
    -C relocation-model=static -C link-args='-nostartfiles -static -no-pie' \
    $cfg_clause-o __one.elf __one.rs"
tools/bin/ngb-pack "$SRCDIR/__one.elf" "$out"
rm -f "$SRCDIR/__one.elf" "$SRCDIR/__one.rs"

echo "mint-one-rust OK $out"
