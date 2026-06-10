# ADR-017 — linear_xor metamorphic relation

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G67

## Context

Rule 90's one-step map is linear over GF(2) (`step(a^b) == step(a)^step(b)`). CRC-style combine bugs and wrong CA rule bytes break linearity while still passing spot checks. The catalog had no homomorphism family (G66 taxonomy gap).

## Decision

Add relation **`linear_xor`** to the metamorphic verifier. For probe pairs `(a,b)`, require `f(a^b) == f(a)^f(b)` with no scalar oracle. Reject witnesses name `a`, `b`, `fab`, `fa`, `fb`, `xor`, `hex=`.

G67 ships a modeled specimen: rule 90 `step` in `fixtures/metamorphic/ca_step.c`; `EVIL_RULE` compiles rule 30 to break linearity.

## Why the adjacent lower layer is insufficient

`involution` and `conserve_popcount` do not state XOR homomorphism. A wrong rule can still be involution-like on some probes.

## What we are not building

- No claim that linearity implies the correct polynomial or rule byte (ceiling, same shape as G24 imposter).
- No `.ngb` format change. I1–I6 hold.

## Demonstrated power versus implemented checks

G67 demonstrates rejection of rule-30 imposter on the pre-registered probe pair. No broader linearity power claim until a second mined bug exercises the branch.

## Kill trigger

If every catch is already `value_oracle` or golden diff on the same witness cost, do not grow this branch.
