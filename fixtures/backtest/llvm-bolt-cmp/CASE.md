# LLVM BOLT cmp_order real-history backtest (G48)

First **cmp_order** relation backtest. Opens the ordering-bug class that equivalence relations and value oracles cannot see.

## The bug

`llvm/llvm-project` BOLT `RewriteInstance::getCodeSections` `compareSections` lambda (`bolt/lib/Rewrite/RewriteInstance.cpp`). With `HotText`, the branch "place hot text movers before anything else" returns true when A is the mover section without checking B. So `cmp(mover, mover)` is true both ways, violating **irreflexivity** (`cmp(a,a)` must be false). libc++ debug builds assert; production sorts silently misorder.

| Revision | SHA | behavior |
| --- | --- | --- |
| buggy parent | `e8606ab` | `cmp(0,0)` returns 1 on mover self-pair |
| fix | `5fe235b` | adds `if (A == B) return false` (+3 lines) |

Upstream: https://github.com/llvm/llvm-project (Apache-2.0 WITH LLVM-exception)

## Pre-registered property

`cmp_order` via `fixtures/metamorphic/llvm_bolt_cmp.req`. `gen_llvm_bolt_cmp` emits the full 4x4 index matrix (16 pairs), witness pair `0 0` first. Section indices: `0=.bolt.hot.text` (mover), `1=.text`, `2=.text.warm`, `3=.text.cold`. `HotText=1`, `HotFunctionsAtEnd=0` (the scenario that exposes the bug). The runner requires each cmp output to be exactly `0` or `1`; a fault is a harness error, never a reject.

| Check | Rule |
| --- | --- |
| Irreflexivity | `cmp(i,i) == 0` |
| Antisymmetry | `cmp(i,j) == 1` implies `cmp(j,i) == 0` |

| Witness pair | hex | Buggy rev | Honest rev |
| --- | --- | --- | --- |
| `(0,0)` mover self | `00` | `got_ij=1` | `0` |

The missing identity guard breaks irreflexivity for any section whose self-comparison reaches a `return true` path, not the mover alone. On the buggy rev `cmp(1,1)=1` (main) and `cmp(2,2)=1` (warm) also violate; `cmp(3,3)=0` because the cold branch compares equal names. `(0,0)` is the pre-registered timeline witness because the verifier scans pairs in order.

## Faithfulness and its limit

`fixtures/metamorphic/llvm_bolt_cmp.c` transcribes the string/name ordering logic from `compareSections` into freestanding C. No LLVM types. The identity guard is strippable; rev2 compiles with `-DCMP_IDENTITY_OK` (parent path). `_start` and argv parse are our trusted driver.

Scope of the relation, stated honestly. G48 demonstrates **irreflexivity** only. The witness `(0,0)` trips `cmp(i,i)==0`. The antisymmetry arm is implemented but this bug does not exercise it: every off-diagonal pair on the buggy rev is consistent (`cmp(0,1)=1`, `cmp(1,0)=0`). Transitivity is not checked. The famous `return a-b` qsort overflow is a **transitivity** break (`INT_MIN, 0, INT_MAX`), so `cmp_order` as built would not catch it. The antisymmetry and transitivity arms wait for a real mined bug before they earn a tested-power claim.

## Mint

```
./scripts/mint-backtest.sh fixtures/metamorphic/llvm_bolt_cmp.c CMP_IDENTITY_OK \
  fixtures/backtest/llvm-bolt-cmp fixtures/metamorphic/llvm_bolt_cmp.req cmp-order
```

## Result

Catch. Timeline accept, reject (`hex=00`), accept. Fix returns to revision one's `graph_root_hash` (`35433a9eed68`).
