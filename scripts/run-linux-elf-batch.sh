#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Runs one .ngb's ELF against many argument pairs in a single backend session.
# Reads "a b" lines on stdin, prints exactly one "a b <stdout>" line per pair,
# even when a run crashes, so a transient fault cannot shift the stream.
# Extract-once plus one container keeps an input sweep fast.

NGb="${1:?usage: run-linux-elf-batch.sh <file.ngb> < pairs}"
TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
ELF="$TMPD/elf"

make -C tools -s bin/ngb-extract >/dev/null
tools/bin/ngb-extract "$NGb" "$ELF"
chmod +x "$ELF"

# A corrupted candidate may crash or loop. Disable the slow qemu core dump and
# bound every probe.
TLIMIT="${ELF_TIMEOUT:-10}"
ulimit -c 0 2>/dev/null || true
PAIRS="$(cat)"

host_to() {
  if command -v timeout >/dev/null 2>&1; then timeout -s KILL "$TLIMIT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout -s KILL "$TLIMIT" "$@"
  else "$@"; fi
}

run_local() {
  local a b out
  printf '%s\n' "$PAIRS" | while read -r a b; do
    [[ -z "${a:-}" ]] && continue
    out="$(host_to "$@" "$ELF" "$a" "$b" 2>/dev/null)" || out=""
    printf '%s %s %s\n' "$a" "$b" "$out"
  done
}

if [[ "$(uname -s)" == "Linux" ]]; then
  run_local
  exit 0
fi

if command -v qemu-x86_64 >/dev/null 2>&1; then
  run_local qemu-x86_64
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
    sh -c 'ulimit -c 0; cat > /tmp/e; chmod +x /tmp/e; printf "%s\n" "$2" | while read -r a b; do [ -z "$a" ] && continue; out=$(timeout -s KILL "$1" /tmp/e "$a" "$b" 2>/dev/null) || out=""; printf "%s %s %s\n" "$a" "$b" "$out"; done' \
    _ "$TLIMIT" "$PAIRS" < "$ELF"
  exit 0
fi

echo "need one of: Linux, qemu-x86_64, or docker" >&2
exit 1
