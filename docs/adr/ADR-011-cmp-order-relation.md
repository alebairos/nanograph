# ADR-011 — cmp_order metamorphic relation

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G48

## Context

G24–G27 proved equivalence relations (`involution`, `round_trip`). G41–G42 used `value_oracle`. Comparator bugs are a different class: a `qsort`-style function can violate **irreflexivity** (`cmp(a,a)` must be false) or **antisymmetry** (if `cmp(a,b)` then `!cmp(b,a)`), breaking strict weak ordering without changing any scalar output a value oracle would check.

LLVM BOLT fix `5fe235b` is a surgical real-history example: the missing `A == B` guard lets any self-comparison that reaches a `return true` branch violate irreflexivity. In the modeled scenario (`HotText=1`, `HotFunctionsAtEnd=0`) that is the mover, main, and warm sections (`cmp(0,0)`, `cmp(1,1)`, `cmp(2,2)` all return 1 on the buggy revision); the cold self-pair stays 0 because the cold branch compares equal names.

## Decision

Add relation **`cmp_order`** to the metamorphic verifier. For a bool comparator `cmp(i,j)` returning `0` or `1` (less-than predicate), the verifier checks a fixed probe table of index pairs:

1. **Irreflexivity:** `cmp(i,i) == 0` for every self pair in the table.
2. **Antisymmetry:** for `i != j`, not (`cmp(i,j) == 1` and `cmp(j,i) == 1`).

No expected value is computed. The contract is the oracle. Reject witnesses name `pair=i,j` and `hex=` as two nybbles.

The runner's output contract is strict: each cmp invocation must print exactly `0` or `1`. Empty or non-bool output (a crashed or faulting candidate) is retried once and then fails as a harness error (`exit 2`). A backend fault is never classified as a semantic reject. Missing `mode`/`domain` keys or an empty pair table are likewise deterministic schema errors, not rejects.

## Why the adjacent lower layer is insufficient

`value_oracle` needs a per-input expected output. `round_trip` needs encode/decode. A comparator violation is a relation between two runs on paired inputs, not a single scalar. The smallest mechanism is a new verifier branch plus a `.req` seam, same pattern as G24.

## What we are not building

- No `.ngb` format change. I1–I6 hold.
- No full transitivity check. Note this means `cmp_order` does **not** catch the famous `return a-b` qsort overflow, which is a transitivity violation (`INT_MIN, 0, INT_MAX`), not irreflexivity or antisymmetry.
- No claim that `cmp_order` proves total correctness of a sort.

## Demonstrated power versus implemented checks

G48 demonstrates **irreflexivity** only. The BOLT bug trips `cmp(mover,mover)==1`. The antisymmetry arm is coded but the bug does not exercise it (every off-diagonal pair on the buggy rev is consistent). Per ADR-007's anti-Goodhart rule, antisymmetry and transitivity get no tested-power claim until a real mined bug exercises them. The honest claim for G48 is one contract invariant caught on real history.

## Is irreflexivity a value oracle in disguise?

The ADR-007 kill trigger asks this. The answer is no. `cmp(i,i)==0` is a universal contract constant true for every comparator, derived from the relation definition, not a per-function expected-output table like G41's `value_oracle`. No spec of the function under test is consulted. It is a contract invariant, not a golden value.

## Kill trigger

If the only bugs we find are already caught by `value_oracle` on single cmp outputs, route them there instead of growing this branch.
