# ADR-012 — size_monotone metamorphic relation

**Status:** Accepted
**Date:** 2026-06-10
**Goal:** G49

## Context

G48 opened the comparator-contract half of the order MR family (`cmp_order`). The literature's other order arm is monotonicity: `x <= y` implies `f(x) <= f(y)`. Size-class rounding functions are the natural codec-adjacent target for allocator maintainers.

jemalloc fix `6b245225459f` is a surgical real-history example: `sz_s2u_compute_using_delta` omitted overflow guards, so ascending requests near `SIZE_T_MAX` can map to a smaller usable size than a smaller request at the top valid class.

## Decision

Add relation **`size_monotone`** to the metamorphic verifier. For ascending probe sizes `x < y`, require `f(x) <= f(y)` with no scalar oracle. Reject witnesses name `x`, `y`, `fx`, `fy`, and `hex=` (the larger request).

## Why the adjacent lower layer is insufficient

`range_coverage` checks declared bounds over a sweep; it does not check pairwise order along the size axis. `value_oracle` needs per-size expected outputs as hard as recomputing the class table. The smallest mechanism is a new verifier branch plus `.req` seam.

## What we are not building

- No `.ngb` format change. I1–I6 hold.
- No claim that `size_monotone` catches interior off-by-one bugs unrelated to order.
- No denial that the demonstrated witness is overflow-boundary rooted; state that honestly in CASE.md.

## Demonstrated power versus implemented checks

G49 demonstrates monotonicity inversion at the top of the `size_t` domain only. Interior probes in the table are included as regression anchors. Per ADR-007, no broader monotonicity power claim until a second mined bug exercises it.

## Kill trigger

If every catch is already a `range_coverage` span bug or a `value_oracle` single-point oracle, route there instead of growing this branch.
