#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

src="${1:-}"
out="${2:-}"
[[ -n "$src" && -n "$out" ]] || { echo "usage: mint-one-go.sh <src.go> <out.ngb>" >&2; exit 1; }
[[ -f "$src" ]] || { echo "mint-one-go: missing $src" >&2; exit 1; }

IMG="golang:1.22"

command -v docker >/dev/null 2>&1 || { echo "mint-one-go: need docker" >&2; exit 1; }
make -C tools -s bin/ngb-pack >/dev/null

SRCDIR="$(cd "$(dirname "$src")" && pwd)"
SRCBASE="$(basename "$src")"

# Compile via a canonical name so the embedded source path, and thus the graph
# hash, depends on source content not the incidental filename. The go tool
# ignores _-prefixed files, so the canonical name is one.go. -trimpath and
# -buildid= keep the build reproducible; symbols stay (ngb-pack reads labels).
docker run --rm --platform linux/amd64 -v "$SRCDIR:/w" -w /w "$IMG" \
  sh -c "cp $SRCBASE one.go && CGO_ENABLED=0 GOFLAGS=-trimpath \
    go build -ldflags='-buildid=' -o __one.elf one.go"
tools/bin/ngb-pack "$SRCDIR/__one.elf" "$out"
rm -f "$SRCDIR/__one.elf" "$SRCDIR/one.go"

echo "mint-one-go OK $out"
