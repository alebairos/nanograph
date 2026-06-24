# Probe generator spike (G73)

Pre-registered eval for the top ICP adoption gap. Answers whether the existing floor can **find** defects without curated witness probes, or only **confirm** them once pointed.

Decision record: [`../adr/ADR-020-adoption-gap-priority.md`](../adr/ADR-020-adoption-gap-priority.md).

## What the backtests proved (confirmation)

Given a probe inside the defect's trigger domain and a correct expected value (or a relation that is its own oracle), the verify floor returns a byte-precise reject witness. Honest builds accept the same probe set. Fifteen real-history timelines replay accept → reject → accept.

That is witness **production**, not defect **discovery**. Probe selection for every backtest used fix-commit knowledge or domain-specific construction (5553-byte adler32 vector, 5414-byte LZW overflow stream, etc.).

## Empirical counterexample (off-domain accept)

Same buggy mint, two probe sets:

| Probe | `zig_adler32_buggy.ngb` verdict |
| --- | --- |
| 5553-byte gradient (curated) | reject |
| `616263` only | accept |

The defect remains in the binary. The pipeline is blind outside the trigger domain.

## Hypothesis under test

A blind probe generator, given only `.req` + relation-native enumeration rules, re-finds a useful fraction of known buggy rev2 witnesses within a fixed budget.

## Non-hypothesis

- Sidecar `.req` recall (G55, separate track, skill-only).
- Freestanding extraction from arbitrary repos (agent-prompt pattern until cost binds).
- Fit scoring or platform expansion (scoping, not engineering).

## Generator inputs (allowed)

From the committed `.req` only:

- `relation`, `entry`, `encode`/`decode`/`mode`, `domain`, `wire`, `reject`
- Declared generator hints (2026-06-11 hardening, #96): `flow_nm`, `seed_start`, `cmp_max`, `probe_style`, `probe_block`. These move driver-protocol facts (e.g. the flow partial length the driver supports, the token block size of the wire format) into the declaration; `blind-probe-generators.sh` carries no domain-keyed switches.
- Relation-native generators already in tree:
  - `round_trip` / `value_oracle` with `wire=hex`: bounded byte/hex enumeration
  - `involution` / `u32` domain: full or stepped sweep (G24)
  - `flow_composition`: `(n,m,seed)` triple schedule (G57–G71 gen scripts as templates)
  - `range_coverage`: seed sweep + optional endpoints from `.req`
  - `value_oracle` with external spec: G23 sum-ordered argv enumeration when `.spec` + `conf-eval` exist

## Generator inputs (forbidden)

- Witness hex from `fixtures/backtest/*/CASE.md`
- `timeline.manifest` reject lines
- Fix-commit SHAs or scorecard notes
- Hand `PROBES=` strings from spike H3 runs

## Corpus

Committed backtest **rev2 (buggy)** `.ngb` files with known witnesses in CASE.md (held out from the generator). Start with relation-diverse subset ≥10:

- utf8, leb128 (round_trip)
- wabt-leb128, capnproto-base64, cosmo-ljson, cosmo-parseip
- knuth-rand-len, llvm-bolt-cmp
- rust-base64, zig-wyhash, go-base64-streaming, rust-crc32fast

## Budget (declare before run)

| Relation family | Initial budget |
| --- | --- |
| round_trip byte domain | first N byte sequences by length then lex order (N=256 default) |
| involution u32 | full u32 sweep (existing) |
| flow_composition | seeds 0..B-1 with fixed (n,m) from gen script defaults (B=64) |
| value_oracle argv | G23 sum-ordered pairs up to sum S (S=32 default) |
| range_coverage | 256 seed sweep (existing) |

Document wall time per case. Raise budget only in a labeled follow-on tranche.

## Pass / fail criteria

| Outcome | Meaning |
| --- | --- |
| **PROVEN (bounded)** | ≥50% of corpus cases get a **true_found** reject within budget (rev1 passes the same witness; value_oracle uses rev1 vs rev2 differential); misses documented with reason |
| **PARTIAL** | 20–49% true_found; generator useful only with relation-specific tuning |
| **REFUTED** | <20% true_found without cheating; floor remains confirmation-only for ICP pitch |

**Specificity control (2026-06-11 follow-on).** A blind `found` on rev2 alone is insufficient. The driver re-checks honest rev1 on the same witness. `both_reject` means both builds fail the declared relation for the same probe (relation-declaration gap, not mined-defect separation). Verdict uses `true_found` rate only.

Either outcome is publishable. Do not tune budget post hoc to pass.

## Deliverables

1. Spike script under `scripts/agent-eval/` (name TBD at implementation).
2. Results markdown table in this file (Results section below).
3. NANO-GOALS claims ledger row for detection.
4. Optional gate only if PROVEN and script is deterministic + fast enough for CI.

## Results

Run: 2026-06-11 (hardened, #96), `./scripts/agent-eval/blind-probe-search.sh --corpus backtest-rev2 --budget default`, wall ~207s (Docker runner). Corpus extended to 13 with `zig-wyhash-native`.

Budget: byte/hex/ascii/u32=256, flow seeds=64. Generator hints declared in `.req` (`flow_nm`, `seed_start`, `cmp_max`, `probe_style`, `probe_block`); empty-output backend faults retried inside `run-linux-elf-capture.sh`.

| Case | Relation | Result | Specificity | wall ms | Notes |
| --- | --- | --- | --- | ---: | --- |
| utf8 | round_trip | miss | — | 4939 | overlong `C080` not in 256-probe decimal budget |
| leb128 | round_trip | miss | — | 5330 | non-minimal `8000` not in first 256 decimal probes |
| wabt-leb128 | round_trip | miss | — | 5229 | 10-byte witness `…ff02` not in first 256 hex strings |
| capnproto-base64 | round_trip | found | **both_reject** | 6501 | witness `AAB=`; honest (WHATWG atob) tolerates nonzero trailing bits, decode `0000` reencode `AAA=`; relation gap stands for this decoder |
| cosmo-ljson | value_oracle | found | true_found | 52586 | differential vs rev1; witness `80` (not curated `c080`) |
| cosmo-parseip | value_oracle | miss | — | 94991 | `255.255.255.256` not in ascii budget |
| knuth-rand-len | range_coverage | found | true_found | 233 | endpoint lo seed=22 hex=02 (matches curated) |
| llvm-bolt-cmp | cmp_order | found | true_found | 389 | pair 0,0 hex=00 (matches curated) |
| rust-base64 | round_trip | found | **true_found** | 6144 | witness `AAB=` (nonzero trailing bits); strict honest rejects, buggy accepts; `probe_block=4` converted the prior false positive |
| zig-wyhash | flow_composition | found | true_found | 562 | seed=0 hex=0 (curated witness uses seed=5) |
| **zig-wyhash-native** | flow_composition | found | **true_found** | 614 | **first blind detection on a native non-C binary**; same witness as the C transcription |
| go-base64-streaming | flow_composition | found | true_found | 17420 | seed=5 hex=5 (`seed_start=1` now declared in `.req`) |
| rust-crc32fast | flow_composition | found | true_found | 3593 | seed=5 hex=5 (matches curated) |

**Summary:** 9/13 rev2 reject (`found`), **8/13 true defect separators (61%)**, 1/13 `both_reject`, 4 miss, 0 error. **Verdict: PROVEN (bounded)** per pre-registered ≥50% **true_found** threshold, now with margin.

**Remaining precision gap.** capnproto's WHATWG-style decoder legitimately tolerates nonzero trailing bits, so `encode∘decode == id` over `probe_block=4` tokens still over-rejects the honest build. The honest relation for that decoder needs a canonical-form domain (zero trailing bits) or a `decode∘encode∘decode == decode` form; the latter would also blind the relation to the mined skip-invalid bug, so the case stays documented as a relation gap rather than silently weakened.

Misses are honest budget/domain-size failures, not confirmation-only on those relations. utf8/leb128/wabt need longer hex/decimal enumeration or structured fuzz, not fix-commit hints.

## Results (holdout generalization, G83 separate row)

Run: frozen holdout eval per [`HOLDOUT-EVAL.md`](HOLDOUT-EVAL.md) (#121). Corpus `holdout-rev1` (5 cases outside `backtest-rev2`). Command: `./scripts/agent-eval/run-holdout-eval.sh`. Budget: default (byte/hex/ascii/u32=256, flow=64). Generators pinned at `freeze_commit` in `fixtures/holdout/preregistration.json`.

| Case | Relation | Result | Specificity | wall ms | Notes |
| --- | --- | --- | --- | ---: | --- |
| jemalloc-s2u | size_monotone | found | true_found | 14261 | overflow phase; reject from `.req` `overflow_size`, not powers-of-2 enumeration (relation-contract confirmation, not blind discovery) |
| conserve-popcount | conserve_popcount | found | true_found | 503 | x=1 blind u32 sweep; clearest independent find |
| knuth-sgb | round_trip | miss | — | 3848 | `domain=knuth_sgb` integers 1..256; witness not in budget |
| go-base64-streaming-native | flow_composition | found | true_found | 24235 | seed=5 (`flow_nm` + `seed_start` from `.req`); train sibling of `go-base64-streaming` (native-binary port, not independent) |
| rust-base64-native | round_trip | found | true_found | 9590 | witness `AAB=`; `probe_block=4` from `.req`; train sibling of `rust-base64` (native-binary port, not independent) |

**Summary (holdout):** 4/5 found, **4/5 true_found (80%)**, 0 `both_reject`, 1 miss, 0 error. **Verdict: generalizes_bounded** per G83 thresholds (≥50% `generalizes_bounded`, <25% `overfit`). Separate from the 8/13 backtest headline; holdout score is never retroactively improved.

**Independence caveat.** The 80% headline is a bounded positive signal, not proof of generalization to unseen bug families. Cases were selected from existing backtests, not freshly mined in a separate session per the #121 ideal. Two cases are native-binary ports of train siblings, and jemalloc rode a witness-derived `.req` field. The strongest single evidence is `conserve-popcount`, one clean blind find on a relation the generator was never pointed at. A freshly mined `holdout-rev2` would close the independence gap. See [`HOLDOUT-EVAL.md`](HOLDOUT-EVAL.md).

## Results (fresh-wire generalization, base32)

Run: 2026-06-19. Question distinct from the holdout: does the blind generator reach a wire format it was never tuned on? Every prior blind win is the base64 wire family or a relation the generator already carried. base32 (RFC 4648) is a new family: 5-bit groups, 8-char blocks, alphabet `A-Z2-7`, same silent trailing-bits bug class.

Two freestanding specimens differ by one line (`#define INVALID_LAST_CHECK` gates out the trailing-bits check). The generator gained `blind_gen_base32_tokens` keyed on `domain=base32`, a mirror of the base64 `probe_block` path with only alphabet and block size changed. No witness baked in.

| Specimen | Blind verdict | Detail |
| --- | --- | --- |
| `base32_honest.ngb` | accept | 248 canonical probes, no false-positive reject |
| `base32_buggy.ngb` | reject | witness `AAAAAAB=` hex `414141414141423d`, decode `00000000` reencode `AAAAAAA=`, ~7s |

The witness emerges from lexicographic enumeration (`=` sorts last, `B` second), not from a planted string. Read: blind reach generalizes to a fresh wire with only alphabet/block parameterization.

**Caveat.** This is a planted bug, the same limit as the backtests and the holdout. It de-risks the lever for unseen wire formats; it is not discovery on real upstream code. That is G84.

## Results (G84 tranche-1, real-upstream discovery)

Run: 2026-06-23 (#126). Question: does blind round_trip find a bug nobody flagged in a real maintained decoder at HEAD? Target selection read the actual source and live behavior before minting, because a reject is only a discovery if the function's contract forbids the input.

Two obvious fresh base-N targets are **trailing-bits-lenient by design**, so a round_trip reject is a relation gap, not a bug. This generalizes the documented capnproto WHATWG case to two more major libraries.

| Target | Source check | Verdict | Classification |
| --- | --- | --- | --- |
| Go `encoding/base32` (go1.22.0) | final byte `dbuf[0]<<3 \| dbuf[1]>>2`, discarded low bits never checked | not minted (source-confirmed lenient) | relation gap |
| CPython `a2b_base64` strict_mode (binascii.c, v3.12.0) | minted faithful specimen, 17/17 vs `python3` oracle | blind reject witness `AAB=` | relation gap, confirmed |

CPython detail. `cpython_base64.ngb` is a faithful transcription (validated against `base64.b64decode(s, validate=True)` on 17 cases incl. the leniency witnesses). Blind round_trip rejects with witness `AAB=` (decode `0000`, reencode `AAA=`). The live interpreter agrees. `base64.b64decode("AAB=", validate=True)` returns `0000` and re-encodes to `AAA=`. CPython accepts the non-canonical input by design (strict_mode promises alphabet + padding + excess-after-padding, not canonical trailing bits). No bug; the reject is the relation gap.

**Tranche-1 read.** No bug-nobody-flagged found. The relation that is cheapest to enumerate (round_trip over canonical base-N bytes) is dominated by designed trailing-bits leniency on real stdlib decoders, which surfaces as relation-gap rejects. The libraries that gave true blind finds (rust-base64) are the ones that **enforce** canonical form. Honest conclusion: blind discovery via round_trip on lenient stdlib decoders is structurally low-yield. Real discovery needs canonical-enforcing contracts or non-leniency relations (involution, cmp_order, conserve_popcount). This sharpens the product claim toward confirmation-plus-witness on code the maintainer already suspects, not blind discovery on arbitrary maintained code.

**Follow-up implemented (poka-yoke, not a new relation).** The leniency false-positive is a contract gap, not a missing relation. `round_trip` already catches the silent-acceptance class on canonical-enforcing decoders; it only mis-signals on decoders that tolerate non-canonical input by design. So `.req` now carries `canonical=enforced|lenient` (default `enforced`). Under `lenient`, a `round_trip` reject is reported as `verdict=relation_gap reason=lenient_contract`, exit 3, instead of a bug. `cpython_base64.req` declares `canonical=lenient` and now self-classifies. Every enforced case is unchanged (verifier re-pinned in `VERIFIER.sha256`; corpus blind run unchanged, `relation_gap=0`). See `METAMORPHIC-RELATIONS.md` VerificationRequest table.

**Idempotence as the lenient second pass (design, not yet built).** For a `lenient` decoder, `round_trip` cannot separate a benign leniency from a hidden inconsistency bug, so it stops at `relation_gap`. The principled second pass is `idempotence` of normalize, `encode(decode(encode(decode(b)))) == encode(decode(b))`. It is leniency-immune (confirmed against CPython: `normalize("AAB=")="AAA="`, stable). A lenient decoder that is self-consistent passes it; a lenient decoder whose encoder and decoder disagree on the canonical subset fails it, surfacing a real bug the leniency was masking. This is the same cheap-pre-filter, expensive-backstop composition as the relation/value-oracle handoff (G25). Build it when a concrete `canonical=lenient` case needs the deeper check; until then it is a relation in search of a defect.

## Results (G85, native-upstream hunt vehicle)

Run: 2026-06-23 (#126). Tranche-1 confirmed the leniency finding against a faithful transcription (`cpython_base64.ngb`). A transcription reject is ambiguous between an upstream bug and a transcription error, which blocks a maintainer-facing report. The native vehicle removes that ambiguity by running the relation against real code.

`scripts/agent-eval/native-hunt.sh` runs `round_trip` against any executable honoring the ELF CLI contract `target <mode> <value>`, reusing `blind-probe-generators.sh` unchanged. It shares the witness format and the `canonical=enforced|lenient` classification with `metamorphic-verify.sh`, and leaves `VERIFIER.sha256` untouched because it is a sibling, not an edit to the pinned verifier. `scripts/agent-eval/check-native-hunt.sh` is the hermetic self-test, an honest strict base32 codec clears `round_trip` (126 canonical tokens) and a trailing-bits-lenient one yields witness `AAAAAAB=`, both run as live python processes.

First mined target. The live CPython base64 codec via `fixtures/native/cpython_base64` (`canonical=lenient`).

| Target | Vehicle | Verdict | Detail |
| --- | --- | --- | --- |
| live `python3` base64 (Python 3.14.3) | native-hunt | relation_gap | witness `AAB=`, decode `0000`, reencode `AAA=`; live interpreter agrees |

This converts the tranche-1 transcription result into a transcription-free confirmation on the actual interpreter. It is an honest null for defects (the decoder is lenient by design) and a positive proof that the vehicle runs end to end on real third-party code.

### Bitcoin prep (CompactSize, canonical-enforcing)

Run: 2026-06-24 (#126). The CPython target proves the vehicle on a lenient contract, where a mismatch is a relation gap. To make a native reject mean a candidate defect, the target must be canonical-enforcing. Bitcoin's CompactSize is that shape, consensus forbids non-minimal encodings, and unlike Bech32m its canonical inputs are trivial to generate blind, so it fits `round_trip` v1 without a checksummed seed corpus.

The target is real `rust-bitcoin` code, not a transcription. `fixtures/native/bitcoin-compactsize` is a small cargo binary depending on `bitcoin = "0.32"`, exposing `csdec` (hex CompactSize to decoded `u64`, or `REJECT`) and `csenc` (`u64` to canonical hex) over `bitcoin::consensus::encode::VarInt`, which returns `NonMinimalVarInt` on non-minimal input. `fixtures/native/bitcoin_compactsize` execs the built binary.

The frozen blind generator stays untouched. CompactSize is a new wire format the holdout-pinned `blind-probe-generators.sh` does not cover, so editing it would break `check-holdout-prereg.sh`. `native-hunt.sh` gained a `probes_cmd` seam, a `.req` may name an external probe source, default stays `blind_gen_probes`. `scripts/agent-eval/gen-compactsize.sh` emits canonical 1-byte and multi-byte encodings plus non-minimal `fd`/`fe`/`ff` forms a correct decoder must reject.

| Target | Vehicle | Verdict | Detail |
| --- | --- | --- | --- |
| real `rust-bitcoin` `VarInt` 0.32 | native-hunt | accept | 43/64 round-trip, 21 non-minimal rejected, none accepted; canonical-enforcing, honest null at HEAD |
| lenient CompactSize (negative control) | native-hunt | reject | witness `fd0000` (non-minimal zero), decode `0`, reencode `00` |

`scripts/check-compactsize-hunt.sh` is the hermetic guard, an honest minimal-enforcing python codec accepts and a non-minimal-lenient one yields the `fd0000` witness on the same probes, so the rust accept is not a blind harness passing everything. No rust or cargo in the guard.

**Next.** rust-bitcoin's `VarInt` is correct, so this is a proven vehicle on real Bitcoin code and an honest null for a defect. The real defect hunt needs a thinner, less-audited Bitcoin-adjacent codec (a third-party CompactSize, address, or Bech32m implementation) wired through the same CLI, where a native reject is a candidate to report upstream. Bech32m differential against published vectors remains the higher-yield branch but needs a seed corpus for valid checksummed strings.

### G86 first native upstream defect (1200wd/bitcoinlib CompactSize)

Run: 2026-06-24 (#126). First reject on real third-party upstream code without transcription, closing the G84 skeptic objection for at least one maintained library.

| Target | Vehicle | Verdict | Detail |
| --- | --- | --- | --- |
| `1200wd/bitcoinlib` `encoding.py` @ `bec99a2` | native-hunt | reject | witness `fdffff`, decode `65535`, reencode `feffff0000`; canonical wire input fails because `int_to_varbyteint` uses `< 0xffff` at the u16 boundary |
| `rust-bitcoin` `VarInt` 0.32 (control) | native-hunt | accept | same probes, honest null |

`fixtures/native/bitcoinlib_compactsize` imports upstream `int_to_varbyteint` / `varbyteint_to_int` when `pip install bitcoinlib` works; otherwise runs a verbatim vendored extract in `fixtures/native/bitcoinlib-vendor/compactsize.py` (same commit). ADR-023 records the policy. `scripts/check-bitcoinlib-compactsize-hunt.sh` gates the witness. Full narrative in `fixtures/backtest/bitcoinlib-compactsize/CASE.md`.

**Next.** Optional maintainer report to `1200wd/bitcoinlib` (human approval before opening). Continue sweep on other huntable-now CompactSize targets or invest in seed-corpus mode for Bech32m.

## Verification

```bash
./scripts/check-canonical-drift.sh
./scripts/agent-eval/blind-probe-search.sh --corpus backtest-rev2 --budget default
```

base32 fresh-wire spike (re-mint from `.c` if `.ngb` absent):

```bash
./scripts/nanograph mint c fixtures/metamorphic/base32_honest.c fixtures/metamorphic/base32_honest.ngb
env METAMORPHIC_BLIND=1 RELATION=round_trip DOMAIN=base32 WIRE=ascii \
  REQ=fixtures/metamorphic/base32.req METAMORPHIC_BLIND_ASCII=256 \
  ./scripts/agent-eval/metamorphic-verify.sh fixtures/metamorphic/base32_buggy.ngb fixtures/metamorphic/base32.req
```

G84 tranche-1 CPython relation-gap (witness reproduces against `python3`):

```bash
env METAMORPHIC_BLIND=1 RELATION=round_trip DOMAIN=cpython_base64 WIRE=ascii \
  REQ=fixtures/metamorphic/cpython_base64.req METAMORPHIC_BLIND_ASCII=256 \
  ./scripts/agent-eval/metamorphic-verify.sh fixtures/metamorphic/cpython_base64.ngb fixtures/metamorphic/cpython_base64.req
python3 -c "import base64; print(base64.b64decode('AAB=', validate=True).hex())"
```

base32 fresh-wire spike (re-mint from `.c` if `.ngb` absent):

```bash
./scripts/nanograph mint c fixtures/metamorphic/base32_honest.c fixtures/metamorphic/base32_honest.ngb
env METAMORPHIC_BLIND=1 RELATION=round_trip DOMAIN=base32 WIRE=ascii \
  REQ=fixtures/metamorphic/base32.req METAMORPHIC_BLIND_ASCII=256 \
  ./scripts/agent-eval/metamorphic-verify.sh fixtures/metamorphic/base32_buggy.ngb fixtures/metamorphic/base32.req
```

Bitcoin CompactSize native hunt (build real rust-bitcoin target, then run):

```bash
cargo build --release --manifest-path fixtures/native/bitcoin-compactsize/Cargo.toml
./scripts/agent-eval/native-hunt.sh fixtures/native/bitcoin_compactsize fixtures/native/bitcoin_compactsize.req
./scripts/check-compactsize-hunt.sh
```

G86 bitcoinlib CompactSize native defect hunt:

```bash
./scripts/agent-eval/native-hunt.sh fixtures/native/bitcoinlib_compactsize fixtures/native/bitcoinlib_compactsize.req
./scripts/check-bitcoinlib-compactsize-hunt.sh
```
