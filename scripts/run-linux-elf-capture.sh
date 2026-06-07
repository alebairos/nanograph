#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NGb="${1:?usage: run-linux-elf-capture.sh <file.ngb> [args...]}"
shift
ELF_ARGS=("$@")
ELF="/tmp/nanograph-elf-capture-$$"

make -C tools -s bin/ngb-extract
tools/bin/ngb-extract "$NGb" "$ELF"
chmod +x "$ELF"

run_elf() {
  if ((${#ELF_ARGS[@]})); then
    "$ELF" "${ELF_ARGS[@]}"
  else
    "$ELF"
  fi
}

run_native() {
  run_elf
}

run_qemu() {
  if ((${#ELF_ARGS[@]})); then
    qemu-x86_64 "$ELF" "${ELF_ARGS[@]}"
  else
    qemu-x86_64 "$ELF"
  fi
}

run_docker() {
  if ((${#ELF_ARGS[@]})); then
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'cat > /tmp/e && chmod +x /tmp/e && exec /tmp/e "$@"' _ "${ELF_ARGS[@]}" < "$ELF"
  else
    docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
      sh -c 'cat > /tmp/e && chmod +x /tmp/e && exec /tmp/e' < "$ELF"
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
