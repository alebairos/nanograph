# ADR-010: round_trip on a UTF-8 codec, the first demo case

Status: accepted (2026-06-08)

## Context

G24-G26 proved metamorphic and value-oracle floors on byte-twiddling functions (`bswap32`, `reverse32`). They are convincing to someone who already believes the thesis. They are not a demo. A demo needs a bug a competent developer would plausibly ship, a unit test that stays green on that bug, and a NanoGraph verdict that names the fault.

UTF-8 decoding has exactly such a bug. Overlong encodings (e.g. `C0 80` for U+0000) are non-canonical byte sequences that a careless decoder accepts. The hole is a real security class, used to smuggle bytes past filters that only check the canonical form. A decoder with the overlong check missing still decodes every valid string correctly, so a unit test built from valid codepoints passes.

## Decision

Add the `round_trip` relation and prove it on a UTF-8 codec, shipped as a demo.

The relation, for a codec with `encode` and `decode`: for every byte sequence `b` the decoder accepts, `encode(decode(b)) == b`. A correct decoder accepts only canonical encodings, so the property holds. An overlong-accepting decoder violates it (`encode(decode(C0 80)) = 00 != C0 80`). The relation is its own oracle.

The specimen `fixtures/metamorphic/utf8.c` packs a byte sequence as `0x01 ++ bytes` into one integer, so a variable-length UTF-8 sequence survives the single-operand two-pass runner. The honest build rejects overlong, surrogate, and out-of-range. `OVERLONG_OK` drops only the overlong lower-bound checks.

The gate `scripts/check-utf8-roundtrip.sh` proves the contrast: the fixed canonical unit test `decode(encode(cp))==cp` is green on the buggy binary, the relation rejects it with witness `bytes=114816 hex=C080 decode=0 reencode=256`.

## Scope note: what NanoGraph verifies, and what it does not assume

The verification floor reads two things, the executed behavior of an artifact through a declared observable (today argv in, stdout out), and the integrity of the byte container. It never parses source. "Language-blind" is literal: the floor sees bytes and behavior, not a language.

The scope is therefore any artifact with a runnable observable, not C. A Rust, Zig, or hand-written assembly binary that reads argv and writes stdout fits the same `metamorphic-verify` and `conf-eval` machinery unchanged. The operational restriction today is the runner, which executes freestanding x86_64 Linux ELF via native, qemu, or docker, and the entry shape, argv operands to stdout. Other observables (files, exit codes, network) and other targets are extensions of the runner, not a redesign of the floor.

It is not even restricted to compiled code in principle. An interpreter plus a script has an entry and an observable too. The integrity half of the story is strongest for a single self-contained artifact, which is why the proven cases are compiled binaries.

## Whitepaper (parked, not written)

The narrative "the unit test passes, NanoGraph rejects with a witness that explains the bug" deserves a logic-and-math writeup with honest references (metamorphic testing literature, the overlong-UTF-8 security history, property-based testing). It is too early. The writeup needs one solid, surprising case to anchor it; G27 is the first candidate. Parked until the case is judged demo-grade by someone outside the project. Do not write it speculatively.

## Consequences

- New relation `round_trip`, no `.ngb` format change. I1-I6 hold.
- The demo is self-contained and deterministic, gated in `check-all-proofs.sh`.
- The packing scheme (`0x01 ++ bytes`) is specific to fixed-width-integer operands; a richer byte-sequence observable would remove it. Parked until a codec needs more than four bytes of output.
- Candidate identification (finding round_trip pairs in real code) stays parked. The request is hand-authored.
