#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "TWO-AGENT-AUDITOR FAIL: $1" >&2; exit 1; }

usage() {
  echo "usage: two-agent-auditor.sh <genesis.ngb> <patched.ngb> <want_stdout> <bundle_out> <verdict_out>" >&2
  exit 2
}

[[ $# -eq 5 ]] || usage

GENESIS="$1"
PATCHED="$2"
WANT_STDOUT="$3"
BUNDLE_OUT="$4"
VERDICT_OUT="$5"

[[ -f "$GENESIS" ]] || fail "missing genesis $GENESIS"
[[ -f "$PATCHED" ]] || fail "missing patched $PATCHED"
[[ -f "$WANT_STDOUT" ]] || fail "missing want_stdout $WANT_STDOUT"

make -C tools -s all >/dev/null

graph_hash() {
  tools/bin/ngb-parse "$1" 2>/dev/null | sed -n 's/.*graph_root_hash=//p'
}

parse_err="$(mktemp)"
set +e
parse_json="$(tools/bin/ngb-parse --json "$PATCHED" 2>"$parse_err")"
parse_code=$?
set -e

{
  printf '%s\n' '--- parse ---'
  if [[ "$parse_code" -eq 0 ]]; then
    printf '%s\n' "$parse_json"
  else
    cat "$parse_err"
  fi
  printf '%s\n' '--- disassemble ---'
  tools/bin/nano-probe disassemble "$PATCHED" 2>/dev/null || true
  printf '%s\n' '--- diff ---'
  tools/bin/nano-probe diff "$GENESIS" "$PATCHED" 2>/dev/null || true
  printf '%s\n' '--- audit-log ---'
  tools/bin/nano-probe audit-log "$PATCHED" 2>/dev/null || true
} >"$BUNDLE_OUT"

rm -f "$parse_err"

if [[ "$parse_code" -ne 0 ]]; then
  inv="$(grep -o 'I[0-9]:[a-z_]*\|root_hash' "$BUNDLE_OUT" | head -1)"
  [[ -z "$inv" ]] && inv="behavior"
  detail="$(grep -o 'ngb-[^ ]*\|I[0-9]:[a-z_]*\|root_hash' "$BUNDLE_OUT" | head -1)"
  [[ -z "$detail" ]] && detail="parse failed"
  printf 'verdict=reject invariant=%s detail=%s\n' "$inv" "$detail" >"$VERDICT_OUT"
  exit 0
fi

got_stdout="$(mktemp)"
set +e
./scripts/run-linux-elf-capture.sh "$PATCHED" >"$got_stdout"
exit_code=$?
set -e

if [[ "$exit_code" -ne 0 ]]; then
  printf 'verdict=reject invariant=behavior detail=exit %s\n' "$exit_code" >"$VERDICT_OUT"
  rm -f "$got_stdout"
  exit 0
fi

if ! cmp -s "$WANT_STDOUT" "$got_stdout"; then
  got_repr="$(xxd -p "$got_stdout" | tr -d '\n')"
  printf 'verdict=reject invariant=stdout detail=got %s\n' "$got_repr" >"$VERDICT_OUT"
  rm -f "$got_stdout"
  exit 0
fi

hash="$(graph_hash "$PATCHED")"
[[ -n "$hash" ]] || fail "accept path missing graph_root_hash"
printf 'verdict=accept graph_root_hash=%s\n' "$hash" >"$VERDICT_OUT"
rm -f "$got_stdout"
