# Mining G51–G53 (language diversity, #70)

Formal mining stages 1–3 per [`BACKTEST.md`](../BACKTEST.md). Scorecards in `fixtures/fit-cases/*.fit`. Wolfram-family hunt exercised against G67 `linear_xor`, G69 `flow_composition`, G50/G68 `conserve_popcount`.

## Wolfram-family verdict

| Family | Rust | Zig | Go |
| --- | --- | --- | --- |
| `flow_composition` | **FIT** crc32fast combine len2=0 | **FIT** Wyhash iterative tail | **FIT** base64 streaming vs one-shot |
| `linear_xor` | PARKED (BE-only crc32fast baseline) | PARKED (no verified fix) | NOT-A-FIT (AVX512+race needs -race) |
| `conserve_popcount` | PARKED (no real-history witness) | PARKED (no verified fix) | PARKED modeled only |

G69 modeled `flow_composition` gains a real-history exercise path in all three languages. G67 `linear_xor` has no FIT survivor in any language on the current x86 argv/stdout floor.

## G51 Rust

| Card | Gate | Priority | Relation | Extraction |
| --- | --- | --- | --- | --- |
| `rust-base64-invalid-last.fit` | FIT | 8 | round_trip | Transcribe `decode_helper` to C (G39 pattern) |
| `rust-crc32fast-combine-len0.fit` | FIT | 7 | flow_composition | Pure fn; freestanding Rust or C |
| `miniz-inflate-huffman.fit` | FIT | 5 | value_oracle | Heavy; strip `init_tree` only |
| `rust-crc32fast-linear-xor-be.fit` | PARKED | n/a | linear_xor | BE simulation required |
| `flate2-crc-combine-overflow.fit` | NOT-A-FIT | n/a | flow_composition | silent_survival=0 |

**G56 survivor:** `rust-base64-invalid-last` (8/8, lowest execution risk). **Wolfram runner-up:** `rust-crc32fast-combine-len0`.

## G52 Zig

| Card | Gate | Priority | Relation | Extraction |
| --- | --- | --- | --- | --- |
| `zig-std-wyhash-iterative.fit` | FIT | 8 | flow_composition | `@export` from `std/hash/wyhash.zig` |
| `zig-std-adler32-large.fit` | FIT | 7 | value_oracle | Freestanding or transcribe |
| `zigimg-gif-lzw-overflow.fit` | FIT | 7 | round_trip | Transcribe + allocator stub |
| `zig-linear-xor-parked.fit` | PARKED | n/a | linear_xor | Kill report |

**G57 survivor:** `zig-std-wyhash-iterative` (validates G69 on real Zig history).

## G53 Go

| Card | Gate | Priority | Relation | Extraction |
| --- | --- | --- | --- | --- |
| `go-base64-streaming.fit` | FIT | 7 | flow_composition | Transcribe streaming `Decoder.Read` |
| `go-hex-decode-dst.fit` | FIT | 7 | value_oracle | Transcribe `hex.Decode` |
| `go-strconv-parseuint.fit` | FIT | 6 | value_oracle | Transcribe `ParseUint` |
| `go-base64-strict-padding.fit` | FIT | 7 | round_trip | Opt-in Strict API |
| `go-crc32-avx512-race.fit` | NOT-A-FIT | n/a | linear_xor adjacent | observable=0 |
| `go-bits-reverse32-modeled.fit` | PARKED | n/a | conserve_popcount | Modeled only |

**G58 survivor:** `go-base64-streaming` (Wolfram `flow_composition` FIT). **Backup:** `go-hex-decode-dst`.

## Stretch G59

Done. Native Zig Wyhash via G59 (`ZIG-WYHASH-NATIVE`); same witness as G57.

## Verification

```bash
./scripts/check-case-fit-rubric.sh
for f in fixtures/fit-cases/rust-*.fit fixtures/fit-cases/zig-*.fit fixtures/fit-cases/go-*.fit fixtures/fit-cases/miniz-*.fit fixtures/fit-cases/flate2-*.fit; do
  ./scripts/score-case-fit.sh "$f"
done
```
