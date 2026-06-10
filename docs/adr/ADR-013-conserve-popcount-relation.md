# ADR-013 — conserve_popcount metamorphic relation

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G50

## Context

Murphy et al.'s permutative MR family asks whether a scalar is preserved under reordering. Mining found no clean real-history, non-memory, freestanding conservation bug in permissive repos. Velox `b4ac86a6804` is the inverse relation (hash wrongly conserved). musl qsort CVE-2026-40200 is memory corruption.

The public-domain `reverse32` specimen already in-tree is the honest modeled carrier: bit reversal permutes positions, so popcount must be conserved.

## Decision

Add relation **`conserve_popcount`** to the metamorphic verifier. For probe inputs `x`, run `f(x)` and require `popcount(f(x)) == popcount(x)`. Reject witnesses name `x`, `hex=`, `pop_in`, `pop_out`.

Ship G50 as a **modeled** backtest with strippable `EVIL_REVERSE_OK` mask typo. Score and park verified real candidates that failed the filter.

## Why the adjacent lower layer is insufficient

`involution` checks `f(f(x))==x`, not scalar conservation. `value_oracle` needs expected outputs per input. Conservation is a pairwise property between input and output statistics, not a second application.

## What we are not building

- No claim that `conserve_popcount` catches biased Fisher-Yates or swap-only shuffle bugs (they remain permutations; popcount is conserved).
- No `.ngb` format change. I1–I6 hold.

## Demonstrated power versus implemented checks

G50 demonstrates popcount break on a bit-dropping mutant. The `involution` floor also rejects the same mutant at `x=1`; the relations are complementary, not redundant, because conservation names the preserved quantity explicitly for permutation-shaped functions.

## Kill trigger

If a real-history conservation bug appears that `value_oracle` or `involution` already catches with the same witness cost, prefer the cheaper floor.
