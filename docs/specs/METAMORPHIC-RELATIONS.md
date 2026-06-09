# Metamorphic relations (G24)

Verify a compiled function against a property that holds with no expected value named. The relation is the oracle. This is the complement to the value-oracle floor (G9-G23): use it where a relation is cheap to state but a value oracle is as hard to build as the function.

Decision: [`../adr/ADR-007-metamorphic-relations.md`](../adr/ADR-007-metamorphic-relations.md).

## VerificationRequest

A language-neutral kv file (`.req`) declares the task. It is the seam between a future language-aware layer that identifies candidates and NanoGraph's language-blind, execution-grounded check.

| Key | Meaning | G24 value |
| --- | --- | --- |
| `relation` | property over runs | `involution` |
| `entry` | how operands reach the binary | `argv` |
| `domain` | input generator | `u32` |
| `eq` | output comparison | `exact` |

`fixtures/metamorphic/bswap32.req`:

```
relation=involution
entry=argv
domain=u32
eq=exact
```

## Relations

| Relation | Property | Status |
| --- | --- | --- |
| `involution` | `f(f(x)) == x` | **Done** (G24) |
| `round_trip` | `encode(decode(b)) == b` over accepted byte sequences | Implemented (G27 utf8, G31 leb128) |
| `range_coverage` | reachability (`lo_seed`/`hi_seed`) plus containment (sweep min/max) | Implemented (G35 knuth_rand_len; G37 endpoints; G38 named phases) |
| `idempotent` | `f(f(x)) == f(x)` | Named, unimplemented |
| `commutative` | `f(a,b) == f(b,a)` | Named, unimplemented |

Each is a branch in the verifier's dispatch. Adding one is a `.req` plus a branch, not a new floor.

## Mechanism

`scripts/agent-eval/metamorphic-verify.sh <candidate.ngb> <request.req>`:

1. Parse the request. Generate the domain sweep (u32: powers of two, `0`, edge bytes, mixed constants).
2. Pass 1, batch `x -> f(x)`. Pass 2, batch `f(x) -> f(f(x))`. Two backend sessions for the whole sweep.
3. Compare `f(f(x))` to `x`. On a violation, confirm with an isolated clean re-run, then print `verdict=reject ... witness x=.. fx=.. ffx=..`.
4. No violation, `verdict=accept ... separator=none`.

The two-pass batched composition reuses `run-linux-elf-batch.sh` (crash-safe per probe) and `run-linux-elf-capture.sh` (isolated confirm) unchanged from G23.

## Gate

`scripts/check-metamorphic-involution.sh` (in `check-all-proofs.sh`, skips with no Linux runner):

- Honest `bswap32` accepts. The relation verifies it with no oracle.
- `bswap32_evil` (rotl8) rejects with witness `x=1` (`f(f(1))=65536 != 1`).
- `bswap32_imposter` (outer-byte swap) accepts. It is an involution but not a byte swap.

## The ceiling

The imposter arm is the bound, asserted as a tested fact. Involution is necessary, not sufficient: a function can satisfy the relation and still be wrong. Separating the imposter from the real `bswap32` needs a value oracle, which is the G9-G23 floor. The two floors are complementary.

Power, not count, is the metric. Rewarding the number of relations invites tautology-stuffing (Goodhart). What G24 measures is whether the relation rejects a wrong program (rotl8) and where that power ends (the imposter).

## Closing the ceiling (G25)

G24 asserts complementarity. G25 demonstrates it on one artifact. Decision: [`../adr/ADR-008-floor-handoff.md`](../adr/ADR-008-floor-handoff.md).

`conf-eval` gains `op=bswap` (single argv operand, u32 decimal). `fixtures/metamorphic/bswap32.spec` plus a `bswap32.cases` hand table give the value oracle its expected output. `scripts/check-bswap-value-oracle.sh` (in `check-all-proofs.sh`) runs both floors on the same `bswap32_imposter`:

- The involution relation accepts it (the ceiling, from G24).
- The value oracle rejects it with witness `x=256` (`got=256 want=65536`).

The handoff is cheap-then-expensive. The relation needs no spec and rejects non-involutions for free; the value oracle costs a computed expected value and separates the involution-but-wrong imposter. Run the relation first, fall back to the oracle only where a value answer is required. The oracle ceiling is narrowed, not removed: where the expected value is as hard to compute as the function, only the relation floor is affordable.

## Real vendored code (G26)

G24 and G25 verified `bswap32`, code we wrote. G26 runs both floors on real, vendored, attributed upstream code. Decision: [`../adr/ADR-009-real-vendored-code.md`](../adr/ADR-009-real-vendored-code.md).

The function under test is the "Reverse bits in parallel" routine from Sean Eron Anderson's Bit Twiddling Hacks (public domain), shipped verbatim in `fixtures/metamorphic/reverse32.c` under a provenance header. The `_start`, parse, and print are our trusted driver. `conf-eval` gains `op=bitrev` (an independent loop, not the parallel form under test). `scripts/check-reverse32-real.sh` (in `check-all-proofs.sh`):

- asserts the upstream attribution is present;
- the involution relation accepts the real bit reversal, and rejects the `EVIL_REVERSE` mask typo (non-involution) with witness `x=1`;
- the value oracle accepts the real bit reversal on a hand table;
- the handoff on real-code's oracle: `bswap32` is an involution the relation accepts, and the value oracle rejects it as bit reversal with witness `x=1` (`got=16777216 want=2147483648`).

The driver calls the function via the C ABI; the compiler emits the call. Hand byte-extraction and instruction-level isolation stay parked. The claim is that NanoGraph verifies real upstream bytes behind a thin trusted harness.

## Round-trip on a codec (G27, demo)

A second relation, `round_trip`, and the first demo framed for an outsider. Decision: [`../adr/ADR-010-utf8-roundtrip-demo.md`](../adr/ADR-010-utf8-roundtrip-demo.md).

For a codec with `encode` and `decode`, the property is: for every byte sequence `b` the decoder accepts, `encode(decode(b)) == b`. A correct decoder accepts only canonical encodings, so this holds. The famous failure is overlong acceptance, where a decoder accepts a non-canonical encoding of a codepoint. Then `decode(b)` succeeds on an overlong `b`, `encode` of that codepoint yields the shorter canonical form, and `encode(decode(b)) != b`. The relation is its own oracle: it never needs the expected codepoint.

The specimen is `fixtures/metamorphic/utf8.c`, an `enc`/`dec` codec over a single integer. A byte sequence is packed as `0x01 ++ bytes` so a variable-length UTF-8 sequence (up to four bytes) survives as one operand for the two-pass runner. The honest decoder rejects overlong, surrogate, and out-of-range forms. `OVERLONG_OK` drops only the overlong lower-bound checks, the classic security hole where `C0 80` decodes to U+0000.

`utf8.req` declares `relation=round_trip` with `encode=enc`, `decode=dec`, and a `reject` sentinel (`1114112`, one past the last codepoint). `metamorphic-verify` runs the domain through `decode` in one batched pass, drops the sequences the decoder rejects, runs the survivors through `encode`, and requires the bytes to come back. A mismatch is confirmed by an isolated decode-then-encode before the reject.

The demo is the contrast. `scripts/check-utf8-roundtrip.sh` (in `check-all-proofs.sh`):

- The fixed canonical unit test `decode(encode(cp))==cp` over five codepoints passes on both the honest and the overlong binary. The bug is invisible to it, because the bug only adds acceptance of non-canonical inputs.
- The relation accepts the honest codec.
- The relation rejects the overlong codec with witness `bytes=114816 hex=C080 decode=0 reencode=256`: the overlong NUL `C0 80` decodes to U+0000 and re-encodes to the canonical `00`.

The unit test stays green. NanoGraph rejects with a witness that names the offending bytes. The two directions are the point: the easy direction (`decode(encode(cp))`) is the test a developer writes; the hard direction (`encode(decode(b))` over a byte domain including malformed input) is the one that catches the bug.

## Round-trip on a second codec (G31, LEB128)

The same `round_trip` relation, unchanged, catches a second codec's bug. `fixtures/metamorphic/leb128.c` is an unsigned LEB128 varint `enc`/`dec` codec with the same `0x01 ++ bytes` packing, capped to four varint bytes. The honest decoder rejects non-minimal encodings. `NONMINIMAL_OK` drops the minimality check, the classic varint hole where `80 00` decodes to zero. `leb128.req` declares `domain=leb128`, the only new code is `gen_leb128` in the verifier. The relation rejects the buggy revision with witness `hex=8000`: `80 00` decodes to 0 and re-encodes to the canonical `00`. This is the proof that the relation and the backtest driver generalize across codecs, not just utf8. See [`../BACKTEST.md`](../BACKTEST.md).

## Range coverage on a generator (G35, G37, G38)

A third relation for bounded generators where neither `round_trip` nor `involution` applies. The driver stays a pure generator (`draw <seed>` prints one draw). The verifier runs two named phases with separate claims and ceilings.

| Key | Meaning |
| --- | --- |
| `draw` | argv mode for one draw |
| `lo`, `hi` | declared inclusive range |
| `reachability` | `on` or `off` (default `on` when both seeds are set, else `off`) |
| `containment` | `sweep` or `off` (default `sweep`) |
| `lo_seed`, `hi_seed` | required when `reachability=on` |

**Phase 1, reachability.** Isolated `draw(lo_seed)` must equal `lo` and `draw(hi_seed)` must equal `hi`. Deterministic endpoint proof. Reject emits `phase=reachability endpoint=lo|hi seed=… got=… want=… hex=…`.

**Phase 2, containment.** When `containment=sweep`, the verifier sweeps the domain (`gen_knuth_rand_len`, 256 seeds) and requires observed `[min,max]` to equal `[lo,hi]`. Sampled bound check for over-reach bugs endpoints alone would miss. Reject emits `phase=containment observed=[…] declared=[…] hex=…`.

Accept reports `reachability=pass|skip containment=pass|skip`. Under-reach bugs (G35) fail reachability first. Over-reach bugs would fail containment.

G35 case: Knuth `gb_flip` plus `rand_len`, `reachability=on`, `containment=sweep`, `lo=1`, `hi=10`, `lo_seed=22`, `hi_seed=2`. Buggy revision fails `phase=reachability` first (`draw(22)` yields 2, witness `hex=02`). See [`../BACKTEST.md`](../BACKTEST.md) and `fixtures/backtest/knuth-rand-len/CASE.md`.

## Specimens

`fixtures/metamorphic/bswap32.c`, freestanding x86_64, reads `argv[1]` as u32, prints the result. Three builds: default (real), `-DEVIL_BSWAP` (rotl8), `-DIMPOSTER_BSWAP` (outer-swap). `fixtures/metamorphic/utf8.c`, `enc`/`dec` modes, default honest and `-DOVERLONG_OK` buggy. Minted by `scripts/mint-metamorphic-fixtures.sh` (pinned `gcc:13`, committed `.ngb`, distinct `graph_root_hash`).

## Not in scope

- No `.ngb` format change. I1-I6 hold.
- No language front end. The request is hand-authored; candidate identification is parked.
- No correctness proof. The sweep is a bounded adversarial sample; the ceiling is the deeper limit.
