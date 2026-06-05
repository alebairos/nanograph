# ADR-002 — Ground-truth conformance floor

**Status:** Accepted (**Build the floor in-house, defer zerolang/MIR coupling**)
**Date:** 2026-06-05
**Goal:** G9 (issue #31)

## Context

A multi-conversation thread refined NanoGraph's reason to exist. Verification is the keystone that lets a human be accountable for autonomous agent code they never read. The framing that survived is **ground-truth conformance**: prove an agent's emitted bytes realize a declared spec, grounded in real execution closest to metal, cheap enough to run at agent speed.

A proposed pipeline pairs zerolang (front end, static semantic verification, owns MIR) with NanoGraph (back end, execution-grounded conformance). The handoff is MIR. That pipeline is attractive but large, and it couples NanoGraph to a second repository it does not own.

## Decision

Build the **self-contained conformance floor** inside NanoGraph. Defer all zerolang/MIR coupling.

The one genuinely new claim hiding in the pipeline is testable without zerolang: the auditor's oracle should be **computed from a spec by an independent reference evaluator**, not hand-written. Today the two-agent auditor compares real stdout to a fixed `WANT_STDOUT` file. That is a looked-up oracle. The increment that matters is compute-not-lookup.

## What we are not building yet

- No MIR ingestion, no zerolang backend contract consumption.
- No reference interpreter for a rich language. The v0 spec is arithmetic only.
- No cross-repo binding manifest.

These wait until the in-house floor is proven and the cost of deriving expectations from a spec is measured on the trivial case.

## Why the adjacent lower layer is insufficient

The existing auditor (`scripts/agent-eval/two-agent-auditor.sh`) reads `WANT_STDOUT`, a fixed file. It cannot demonstrate trust-decoupled conformance, because the expectation is supplied, not derived. A reference evaluator that computes the expectation from a spec, and never reads the bytes, is the smallest mechanism that closes that gap.

## Design

- `ConfSpec` = `{ op in {add,sub,mul}, a, b, yield=exit }`, key=value lines.
- `tools/bin/conf-eval` computes the expected integer from the spec. It reads only the spec, never the `.ngb` or ELF. That independence is the property under test.
- `scripts/agent-eval/conformance-check.sh <spec> <ngb>` runs the real ELF via `run-linux-elf-capture.sh`, then accepts iff observed exit equals computed expected.

## Evidence (measured 2026-06-05, existing fixtures)

| Spec | Bytes | Computed | Observed | Verdict |
| --- | --- | --- | --- | --- |
| `add(1,1)` yield=exit | `add_two.ngb` | 2 | 2 | accept |
| `add(1,1)` yield=exit | `add_two_patched.ngb` | 2 | 3 | reject |
| `add(1,1)` yield=exit | `add_two_chain.ngb` | 2 | 4 | reject |

The expectation `2` is computed by `conf-eval` from `1+1`, independent of either binary. The floor accepts the binary whose real execution matches, and rejects the ones that do not. `add_two_patched` is the true miscompilation negative, same spec with the `add` immediate at offset 127 flipped from `01` to `02` so it computes `1+2=3`. `add_two_chain` is the weaker divergent-program negative.

## Known limit

The floor is only as strong as the reference evaluator. If `conf-eval` shared a bug with the byte producer, a wrong program would pass. Independent, minimal authorship of `conf-eval` is what gives the floor teeth. The miscompilation negative `add_two_patched` closes the earlier gap, same spec `add(1,1)` with a flipped immediate computing 3. The divergent `add_two_chain` is kept as the weaker negative.

## Kill trigger

If deriving the expected consequence from even the trivial spec turns out to need most of a real interpreter, the compute-not-lookup property is not cheap, and the floor's claim to run at agent speed weakens. That cost signal stops further investment in spec-derived oracles.
