#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

src="${1:-}"
out="${2:-}"
shift 2 || true

[[ -n "$src" && -n "$out" ]] || { echo "usage: mint-one-go.sh <src.go> <out.ngb> [--tags tag,...]..." >&2; exit 1; }
[[ -f "$src" ]] || { echo "mint-one-go: missing $src" >&2; exit 1; }

build_tags=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tags)
      [[ -n "${2:-}" ]] || { echo "mint-one-go: --tags needs a value" >&2; exit 1; }
      build_tags="$2"
      shift 2
      ;;
    *) echo "mint-one-go: unknown arg $1" >&2; exit 2 ;;
  esac
done

IMG="golang:1.22"

command -v docker >/dev/null 2>&1 || { echo "mint-one-go: need docker" >&2; exit 1; }
make -C tools -s bin/ngb-pack >/dev/null

SRCDIR="$(cd "$(dirname "$src")" && pwd)"
SRCBASE="$(basename "$src")"
stem="${SRCBASE%.go}"

gos=("$SRCBASE")
shopt -s nullglob
for f in "$SRCDIR/${stem}"_*.go; do
  gos+=("$(basename "$f")")
done
shopt -u nullglob

tags_flag=""
[[ -n "$build_tags" ]] && tags_flag="-tags $build_tags"

builddir="$SRCDIR/.mint-go-build"
rm -rf "$builddir"
mkdir -p "$builddir"
trap 'rm -rf "$builddir"' EXIT
for g in "${gos[@]}"; do
  cp "$SRCDIR/$g" "$builddir/"
done
printf 'module mint\n\ngo 1.22\n' >"$builddir/go.mod"

docker run --rm --platform linux/amd64 -v "$builddir:/w" -w /w "$IMG" \
  sh -c "CGO_ENABLED=0 GOFLAGS=-trimpath go build -ldflags='-buildid=' $tags_flag \
    -o __one.elf ."
elf_tmp="$builddir/__one.elf"
tools/bin/ngb-pack "$elf_tmp" "$out"

echo "mint-one-go OK $out"
