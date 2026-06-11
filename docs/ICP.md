# Ideal customer profile

Positioning, not philosophy. The concept lives in [`../nanograph.md`](../nanograph.md). This page names who NanoGraph is for and why, based on what G24-G27 proved.

## The one customer

A maintainer of correctness-critical, hard-to-oracle, compiled code, where a wrong answer is silent and expensive. The sharpest instance today is a **codec, serializer, or parser maintainer**. UTF-8, varint and LEB128, protobuf and CBOR, base64, compression framing, instruction encoders.

They ship a library other people's bytes flow through. They already think in round-trips and invariants. They have unit tests and still get burned by the input they did not think to write down.

## Why them, in order

1. **The oracle is the problem.** For their functions the expected output is as hard to compute as the function itself. A conventional test names input and expected output by hand. That is exactly where coverage thins and where the dangerous inputs hide. NanoGraph's relations need no expected value. `encode(decode(b)) == b` is its own oracle.
2. **The bug is silent and security-relevant.** Overlong UTF-8, a varint that does not reject a non-minimal encoding, a length prefix that disagrees with the body. These do not crash. They pass tests. They become CVEs. The audience already fears this class.
3. **Unit tests give false confidence here.** The G27 demo is the wedge. The canonical round-trip test stays green on a decoder with the overlong hole, because the bug only adds acceptance of input the test never sends. The maintainer has felt this exact gap.
4. **They are invariant-native.** You do not have to teach a codec author what a round-trip is. The `VerificationRequest` (relation, domain, eq) is a language they already speak. Adoption cost is low.
5. **The verdict is actionable.** NanoGraph rejects with the offending bytes (`C0 80`), not a coverage percentage. A maintainer can act on a witness in seconds.

## The wedge

Metamorphic relations plus an execution-grounded verdict with a byte-level witness. The agent or developer proposes the change. NanoGraph runs the real binary over an adversarial domain and either accepts or hands back the input that breaks the stated property. No source parsing, so the same machinery serves any language that compiles to a runnable artifact.

## Scoring a candidate

The ICP is the who. [`CASE-FIT-RUBRIC.md`](CASE-FIT-RUBRIC.md) is the test for a specific function. Score any candidate with `scripts/score-case-fit.sh` before committing a goal. A case is a fit only when oracle hardness, property checkability, observability, and silent-bug survival are all nonzero at once. Criticality is a separate axis that sets priority among fits, not membership.

## Who it is not for, and why (candor)

- **App and product developers with easy oracles.** If the expected output is cheap to write, a normal test already wins. NanoGraph adds nothing.
- **Pure dynamic, interpreted glue with no stable artifact.** The integrity half of the story wants a self-contained binary. Weak fit until the runner grows other observables.
- **Teams that want a coverage number.** NanoGraph produces a verdict and a witness, not a percentage. Wrong tool for that buyer.
- **Anyone wanting a correctness proof.** The sweep is a bounded adversarial sample, not a proof. Honest scope.

## Evidence so far

- G24–G27. Metamorphic relations, floor handoff, real vendored code, UTF-8 demo (`scripts/demo-utf8.sh`).
- G30–G72. Fifteen real-history backtest timelines with byte witnesses (confirmation, not blind detection).
- G55 follow-on (#85–#87). Frozen sidecar recalls `.req` on house-style specimens; skill-only; prose dependency documented.

## What is not yet proven

Hand-authored request on one codec was the wedge. Backtests now cover fifteen real-history cases. G73 blind search finds **6/12 true defect separators** at default budget (8/12 rev2 reject, 2 relation-declaration false positives on base64). Four misses remain budget-limited (utf8 overlong, leb128 non-minimal, wabt 10-byte, parseip wrap).

No maintainer outside this project has validated the pitch. Extraction remains an agent-prompt pattern, not a product.

## Adoption today (honest pitch)

NanoGraph is a **verification pattern**, not an installable tool. A maintainer transcribes one function into a freestanding specimen, writes or generates a `.req`, and runs the floor. Expect x86_64 Linux ELF via Docker on macOS. Expect a reject witness when probes hit the defect domain, not automatic bug discovery.

Four gaps, priority order per ADR-020:

1. **Probe generator** (G73, **done bounded**). Blind search finds 6/12 true defect separators at default budget; 2/12 `both_reject` expose relation-declaration gaps (base64 round_trip on unpadded input). Misses are domain-size/budget.
2. **Extractor** (agent delegates today; productize when a paying candidate binds cost).
3. **Fit** (score with `score-case-fit.sh`; most code is NOT-A-FIT).
4. **Platform** (narrow by design; APE rejected).

Spec: [`specs/PROBE-GENERATOR-SPIKE.md`](specs/PROBE-GENERATOR-SPIKE.md). Decision: [`adr/ADR-020-adoption-gap-priority.md`](adr/ADR-020-adoption-gap-priority.md).

## The signal that would confirm or kill the bet

Confirm: a real codec or serialization maintainer, shown the demo, points at a function in their own tree and says "I want this on that." Kill: they shrug, because their existing property-based tests already cover it. Until one of those happens, the ICP is a hypothesis with four proofs behind it, not a validated market.
