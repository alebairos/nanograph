# ADR-009 — Verify real vendored upstream code behind a trusted driver

**Status:** Accepted (**The floors run on bytes we did not author**)
**Date:** 2026-06-08
**Goal:** G26 (issue #47)

## Context

G24 and G25 verified `bswap32`, code we wrote. A floor that only ever checks its author's own specimens proves a mechanism, not a claim about real software. The usage model is an agent importing a real function and NanoGraph verifying it. That had not been shown.

## Decision

Run both floors on a real, vendored, attributed upstream algorithm. The function under test is the "Reverse bits in parallel" routine from Sean Eron Anderson's Bit Twiddling Hacks, placed by the author in the public domain. It ships verbatim in `fixtures/metamorphic/reverse32.c` under a provenance header. The `_start`, argv parse, and print are our trusted driver. Bit reversal is an involution and is not a byte swap, so it exercises the relation floor and needs the value oracle to be told apart from another involution.

## Why bit reversal, not bswap again

A faithful `bswap32` body is almost the bytes we already wrote, so vendoring it would prove nothing new. Bit reversal is a different, recognizable algorithm (FFT, CRC, DSP), it is an involution, and a planted mask typo gives a realistic non-involution bug. It also reuses `bswap32` for free as the involution-but-not-bit-reversal imposter in the handoff.

## What the gate shows

`scripts/check-reverse32-real.sh` asserts the attribution is present, then:

- The involution relation accepts the real bit reversal with no oracle.
- The relation rejects the `EVIL_REVERSE` mask typo (non-involution) with witness `x=1` (`f(f(1))=0`).
- `conf-eval op=bitrev` (an independent loop, not the parallel form under test) matches a hand table.
- The value oracle accepts the real bit reversal on every case.
- The handoff: `bswap32` is an involution the relation accepts, and the value oracle rejects it as bit reversal with witness `x=1` (`got=16777216 want=2147483648`).

## Why the adjacent lower layer is insufficient

The G24 relation cannot tell two involutions apart, and the G25 value oracle had only been shown on our own `bswap32`. The smallest move that lifts the claim to real code is to vendor a real algorithm behind a trusted driver and add one `conf-eval` op. No new floor tier, no `.ngb` format change. I1-I6 hold.

## Trusted boundary

The driver is trusted glue; the vendored function is the artifact. The driver calls the function via the C ABI, so the compiler emits the SysV AMD64 call. We did not hand-extract function bytes or invoke them through a trampoline. That deeper isolation is gem5-adjacent and stays parked per the ledger. The honest claim is that NanoGraph verifies real upstream bytes compiled behind a thin harness, not that it isolates a function at the instruction level.

## Known limit

Provenance here is a header attribution plus a faithful vendored body, asserted by a grep in the gate. It is not a cryptographic link to an upstream commit. A stronger provenance (pinned source hash) is a later option if an auditor needs it.

## Kill trigger

If verifying a real function needs linking libc or a runtime the freestanding pipeline cannot host, stop vendoring whole programs and revisit whether function-level ABI invocation must be built after all.
