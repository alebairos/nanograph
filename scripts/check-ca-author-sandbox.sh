#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CHECK-CA-AUTHOR-SANDBOX FAIL: $1" >&2; exit 1; }

echo "== ca author sandbox (G18) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SANDBOX="$WORK/sandbox"
./scripts/agent-eval/prepare-author-sandbox-ca.sh "$SANDBOX"

for want in genesis.ngb intent.spec author/SKILL.md bin/ngb-parse bin/nano-probe MANIFEST.sha256; do
  [[ -f "$SANDBOX/$want" ]] || fail "missing $want"
done

if find "$SANDBOX" -type l | grep -q .; then
  fail "sandbox contains symlinks"
fi

count="$(find "$SANDBOX" -type f | wc -l | tr -d ' ')"
[[ "$count" -le 8 ]] || fail "sandbox has $count files (expected <= 8)"

if grep -rE 'patch_off=4424|5a:1e|ca_rule30_v1|rule30\.golden' "$SANDBOX" >/dev/null 2>&1; then
  fail "sandbox leaks oracle literals"
fi

grep -q 'op=eca' "$SANDBOX/intent.spec" || fail "intent.spec missing op=eca"
grep -q 'rule=30' "$SANDBOX/intent.spec" || fail "intent.spec missing rule=30"

"$SANDBOX/bin/ngb-parse" "$SANDBOX/genesis.ngb" >/dev/null 2>&1 || fail "ngb-parse failed in sandbox"
"$SANDBOX/bin/nano-probe" disassemble "$SANDBOX/genesis.ngb" >/dev/null 2>&1 || fail "nano-probe failed in sandbox"

EMPTY_STREAM="$WORK/empty.jsonl"
: >"$EMPTY_STREAM"
./scripts/agent-eval/audit-author-isolation.sh "$SANDBOX" "$EMPTY_STREAM" >/dev/null

LEAK_STREAM="$WORK/leak.jsonl"
printf '%s\n' '{"tool_call":{"readToolCall":{"args":{"path":"/tmp/nanograph/fixtures/ca/rule30.golden"}}}}' >"$LEAK_STREAM"
set +e
./scripts/agent-eval/audit-author-isolation.sh "$SANDBOX" "$LEAK_STREAM" >/dev/null 2>&1
leak_code=$?
set -e
[[ "$leak_code" -ne 0 ]] || fail "audit should reject forbidden path read"

echo "CHECK-CA-AUTHOR-SANDBOX OK"
