#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NGb="${1:-fixtures/hello.ngb}"
ELF="/tmp/nanograph-hello-test"

make -C tools -s bin/ngb-extract
tools/bin/ngb-extract "$NGb" "$ELF"
chmod +x "$ELF"

run_native() {
  "$ELF"
}

run_qemu() {
  qemu-x86_64 "$ELF"
}

run_docker() {
  docker run --rm --platform linux/amd64 -i "ubuntu:24.04" \
    sh -c 'cat > /tmp/e && chmod +x /tmp/e && /tmp/e' < "$ELF"
}

if [[ "$(uname -s)" == "Linux" ]]; then
  run_native
  echo "ran linux elf natively"
  exit 0
fi

if command -v qemu-x86_64 >/dev/null 2>&1; then
  run_qemu
  echo "ran linux elf via qemu-x86_64"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  run_docker
  echo "ran linux elf via docker ubuntu:24.04"
  exit 0
fi

echo "need one of: Linux, qemu-x86_64 (brew install qemu), or docker" >&2
exit 1
