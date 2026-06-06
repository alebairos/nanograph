#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "CA-ORACLE FAIL: $1" >&2; exit 1; }

echo "== ca oracle (G17 phase 1) =="
make -C tools -s bin/conf-eval >/dev/null

RULE90="fixtures/ca/rule90.spec"
RULE30="fixtures/ca/rule30.spec"
GOLDEN="fixtures/ca/rule30.golden"
[[ -f "$RULE90" ]] || fail "missing $RULE90"
[[ -f "$RULE30" ]] || fail "missing $RULE30"
[[ -f "$GOLDEN" ]] || fail "missing $GOLDEN"

echo "-- rule 90: row k population == 2^popcount(k) (closed form, independent of conf-eval) --"
inv="$(tools/bin/conf-eval "$RULE90" | awk '
  { n=gsub(/#/,"#"); k=NR-1; pc=0; kk=k;
    while (kk>0) { pc+=kk%2; kk=int(kk/2) }
    e=1; for (i=0;i<pc;i++) e*=2;
    if (n!=e) { printf "row %d ones=%d expect=%d\n", k, n, e; bad++ } }
  END { if (bad) exit 1 }
')" || fail "rule 90 popcount invariant violated: $inv"
echo "rule90 popcount invariant holds for all rendered rows"

echo "-- rule 30: conf-eval reproduces independently minted golden byte-for-byte --"
diff <(tools/bin/conf-eval "$RULE30") "$GOLDEN" >/dev/null || fail "rule 30 render diverges from golden"
echo "rule30 matches golden"

echo "CA-ORACLE OK (rule90 invariant + rule30 golden)"
