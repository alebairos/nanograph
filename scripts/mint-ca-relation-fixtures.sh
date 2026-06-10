#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MM="fixtures/metamorphic"
IMG="gcc:13"
FLAGS="-static -nostdlib -ffreestanding -no-pie -fno-stack-protector"

command -v docker >/dev/null 2>&1 || { echo "mint-ca-relation: need docker" >&2; exit 1; }
[[ -f "$MM/ca_step.c" && -f "$MM/ca_flow.c" ]] || {
  echo "mint-ca-relation: missing ca_step.c or ca_flow.c" >&2
  exit 1
}

make -C tools -s bin/ngb-pack bin/ngb-parse >/dev/null

docker run --rm --platform linux/amd64 -v "$ROOT/$MM:/w" -w /w "$IMG" sh -c "
  gcc -O0 $FLAGS -DRULE=90 -o ca_step90.elf ca_step.c &&
  gcc -O0 $FLAGS -DRULE=90 -DEVIL_RULE -o ca_step90_evil.elf ca_step.c &&
  gcc -O0 $FLAGS -DRULE=184 -o ca_step184.elf ca_step.c &&
  gcc -O0 $FLAGS -DRULE=184 -DEVIL_DROP -o ca_step184_evil.elf ca_step.c &&
  gcc -O0 $FLAGS -DRULE=90 -o ca_flow90.elf ca_flow.c &&
  gcc -O0 $FLAGS -DRULE=90 -DEVIL_SKIP -o ca_flow90_evil.elf ca_flow.c
"

for pair in \
  ca_step90.elf:ca_step90.ngb \
  ca_step90_evil.elf:ca_step90_evil.ngb \
  ca_step184.elf:ca_step184.ngb \
  ca_step184_evil.elf:ca_step184_evil.ngb \
  ca_flow90.elf:ca_flow90.ngb \
  ca_flow90_evil.elf:ca_flow90_evil.ngb; do
  elf="${pair%%:*}"
  ngb="${pair#*:}"
  tools/bin/ngb-pack "$MM/$elf" "$MM/$ngb"
done
rm -f "$MM"/*.elf

hashes=()
for ngb in ca_step90.ngb ca_step90_evil.ngb ca_step184.ngb ca_step184_evil.ngb ca_flow90.ngb ca_flow90_evil.ngb; do
  h="$(tools/bin/ngb-parse "$MM/$ngb" | sed -n 's/.*graph_root_hash=//p')"
  hashes+=("$h")
  echo "$ngb ${h:0:12}"
done

uniq="$(printf '%s\n' "${hashes[@]}" | sort -u | wc -l | tr -d ' ')"
[[ "$uniq" -eq "${#hashes[@]}" ]] || { echo "mint-ca-relation: fixture hash collision" >&2; exit 1; }
echo "mint-ca-relation-fixtures OK"
