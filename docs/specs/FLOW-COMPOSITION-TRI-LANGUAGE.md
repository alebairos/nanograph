# Tri-language flow_composition witness equivalence (G72)

Compares mined real-history `flow_composition` catches across Rust, Zig, and Go against the modeled G69 CA specimen.

## Scope

This doc records witness equivalence at the relation level. It does not claim byte-identical binaries or shared probe domains across languages.

## Modeled baseline (G69)

| Field | Value |
| --- | --- |
| Specimen | `fixtures/metamorphic/ca_flow90.ngb` |
| Relation | `flow_composition` |
| Evil mutant | `ca_flow90_evil.ngb` (`EVIL_SKIP`) |
| Pre-registered triple | `(1, 2, 5)` |
| Witness | seed component in reject line |

G69 proves the verifier relation catches skipped-generation drift on iterated rule-90 CA.

## Mined real-history lane (tri-language)

All three use the same relation schema (`flow_composition`, `mode=flow`, probe triples `(n,m,seed)`). Each ships its own domain-specific driver and probe generator.

| Goal | Language | Upstream | Gate | Witness `hex=` | Bug shape |
| --- | --- | --- | --- | --- | --- |
| G57 | Zig (C transcription) | `ziglang/zig` Wyhash | `ZIG-WYHASH` | `5` | incremental hash drops tail |
| G58 | Go | `golang/go` base64 streaming | `GO-BASE64-STREAMING` | `5` | streaming decode drops tail fragment |
| G71 | Rust | `srijs/rust-crc32fast` combine | `RUST-CRC32FAST-COMBINE-LEN0` | `5` | `len2=0` combine returns xor |

G59 re-proves G57 witness on native Zig (`ZIG-WYHASH-NATIVE`, same `hex=5`).

## Equivalence claim (bounded)

**Proven.** All three mined backtests plus G69 modeled CA reject an incremental-vs-one-shot mismatch under `flow_composition` with pre-registered triples. The witness seed `hex=5` aligns across Zig, Go, and Rust for the primary timeline catch.

**Not claimed.**

- Cross-language probe interchangeability (each domain has its own `gen_*` probe table).
- Shared `.ngb` graph roots across languages.
- That `flow_composition` subsumes `round_trip` or `linear_xor` on these bugs (see `scripts/measure-relation-impact.sh`).

## Separation vs G69 modeled CA

| Specimen | `flow_composition` | Notes |
| --- | --- | --- |
| `ca_flow90.ngb` | accept | honest modeled CA |
| `ca_flow90_evil.ngb` | reject | `EVIL_SKIP` |
| `zig_wyhash_rev2.ngb` | reject | mined Wyhash tail |
| `go_base64_streaming_rev2.ngb` | reject | mined streaming tail |
| `rust_crc32fast_combine_rev2.ngb` | reject | mined len2=0 combine |

G56 (`round_trip` on Rust base64) exercises a different relation family. It closes the Rust language-diversity lane but is outside this flow_composition equivalence table.

## Verification

```bash
./scripts/check-flow-composition.sh
./scripts/check-backtest.sh fixtures/backtest/zig-wyhash/timeline.manifest 5 ZIG-WYHASH
./scripts/check-backtest.sh fixtures/backtest/go-base64-streaming/timeline.manifest 5 GO-BASE64-STREAMING
./scripts/check-backtest.sh fixtures/backtest/rust-crc32fast-combine/timeline.manifest 5 RUST-CRC32FAST-COMBINE-LEN0
./scripts/measure-relation-impact.sh
```

## Verdict

**PROVEN (bounded).** Tri-language `flow_composition` real-history exercise path is complete with Rust G71. Witness `hex=5` is the shared primary timeline seed across Zig, Go, and Rust mined catches.
