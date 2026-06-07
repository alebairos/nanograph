#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NGb="${1:?usage: run-linux-elf-capture.sh <file.ngb> [args...]}"
shift
ELF_ARGS=("$@")
ELF="/tmp/nanograph-elf-capture-$$"

# Untrusted or corrupted bytes may crash or loop. A corrupt ELF under qemu dumps
# core, and writing that core is pathologically slow, so disable it. timeout
# bounds a genuine loop. Do not exec the ELF as PID 1: a fatal signal to PID 1
# in the container stalls; keeping a shell parent lets the crash reap fast.
TLIMIT="${ELF_TIMEOUT:-10}"
ulimit -c 0 2>/dev/null || true

make -C tools -s bin/ngb-extract
tools/bin/ngb-extract "$NGb" "$ELF"
chmod +x "$ELF"

host_to() {
  if command -v timeout >/dev/null 2>&1; then timeout -s KILL "$TLIMIT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout -s KILL "$TLIMIT" "$@"
  else "$@"; fi
}

run_native() {
  if ((${#ELF_ARGS[@]})); then host_to "$ELF" "${ELF_ARGS[@]}"; else host_to "$ELF"; fi
}

run_qemu() {
  if ((${#ELF_ARGS[@]})); then host_to qemu-x86_64 "$ELF" "${ELF_ARGS[@]}"; else host_to qemu-x86_64 "$ELF"; fi
}

run_docker() {
  if ((${#ELF_ARGS[@]})); then
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'ulimit -c 0; cat > /tmp/e && chmod +x /tmp/e && timeout -s KILL '"$TLIMIT"' /tmp/e "$@"' _ "${ELF_ARGS[@]}" < "$ELF"
  else
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'ulimit -c 0; cat > /tmp/e && chmod +x /tmp/e && timeout -s KILL '"$TLIMIT"' /tmp/e' < "$ELF"
  fi
}

if [[ "$(uname -s)" == "Linux" ]]; then
  run_native
  exit $?
fi

if command -v qemu-x86_64 >/dev/null 2>&1; then
  run_qemu
  exit $?
fi

if command -v docker >/dev/null 2>&1; then
  run_docker
  exit $?
fi

echo "need one of: Linux, qemu-x86_64 (brew install qemu), or docker" >&2
exit 1
