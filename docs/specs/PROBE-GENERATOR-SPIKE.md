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

### G87 differential relation (Bech32m + Base58Check huntable)

Run: 2026-06-24 (#126). `round_trip` catches bijection bugs only. A decoder that accepts an invalid input re-encodes to the same string and passes, so the headline Bech32m bugs (witness version > 16, checksum-variant confusion) are invisible to it. `native-hunt.sh` gained `relation=differential`, comparing the target against a trusted reference on the same mode and probes. A divergence is the witness.

| Domain | Relation | Reference | Catches | Self-test |
| --- | --- | --- | --- | --- |
| Bech32m | differential | `sipa/bech32` `segwit_addr.py` (vendored) | witver>16 acceptance (rust-bech32 #274 shape), checksum-variant | `check-bech32m-differential.sh` |
| Base58Check | round_trip (seed corpus) | none (bijection) | leading zero-byte loss | `check-base58check-hunt.sh` |

`gen-bech32m.sh` mints valid-checksum segwit addresses across witness versions 0..31 plus BIP350 vectors. Versions 17 and 31 carry a valid Bech32m checksum but are invalid per BIP350; the reference rejects them, a lenient target accepts, they diverge. Witness on version 17 (`bc13...`, `target_out=17:...` vs `reference_out=REJECT`). `gen-base58check.sh` mints spec-valid Base58Check strings including leading zero-byte payloads; a bignum decoder drops the leading `1` and fails the re-encode (witness `16L5...` re-encodes to `6L5...`).

Both are hermetic honest-vs-buggy self-tests that prove the vehicle separates the class. The real hunt wires a fetched third-party Bech32m or Base58 library as the target against the vendored reference; that is the follow-on.

#### Divergence-direction asymmetry (triage)

A real run against the pre-BIP350 `bech32` 1.2.0 diverged on the first Taproot probe, but it was a false positive. That library has no Bech32m support, so rejecting a Bech32m address is correct, not a defect. The direction of the divergence is the triage. The target rejecting what the reference accepts is a version or capability gap (`verdict=capability_gap`, exit 3). The target accepting what the reference rejects, or both accepting and disagreeing, is the defect-bearing direction (`verdict=reject`, exit 1). The classifier is encoded in `native-hunt.sh` and asserted three ways in `check-bech32m-differential.sh` (honest concurs, witver>16-lenient is a defect, bech32-only is a capability_gap).

#### Long-tail sweep (2026-06-24, #126)

Installable PyPI codecs run as targets against the canonical reference. All install pure-Python with no `gmp`/`fastecdsa` friction.

| Target | Surface | Verdict |
| --- | --- | --- |
| `bech32m` 1.0.0 | differential (witver 0..31, cross-spec) | accept (concurs, correct) |
| `bech32` 1.2.0 | differential | capability_gap (pre-BIP350, no Bech32m) |
| `base58` 2.1.1 | leading-zero | null (preserves leading zeros) |
| `base58check` 1.0.2 | leading-zero | null (preserves leading zeros) |
| `based58` 0.1.1 | leading-zero | null (preserves leading zeros) |

No defect in the maintained PyPI long tail. These libraries are correct on the probed surfaces. The classifier correctly labels `bech32` 1.2.0 as a capability gap rather than a false defect. Reaching a defect now requires GitHub-only ports and altcoin forks not packaged on PyPI, each needing per-target glue, or wider probe surfaces (mixed case, length>90, HRP validation).

### G88 pinned historical repro (base-x CVE-2025-27611)

Run: 2026-06-26 (#126). Converted the recommendation into a checkable repro loop using a known vulnerable historical version and its fixed comparator.

| Target | Relation | Witness | Verdict |
| --- | --- | --- | --- |
| `base-x@5.0.0` (pinned vulnerable) | differential (`b58dec`) vs strict Base58 reference | `ABCĀDEF` (`hex=414243c480444546`) | `reject` with `reason=target_accepts_reference_rejects`, `target_out=50f12020b0`, `reference_out=REJECT` |
| `base-x@5.0.1` (pinned fixed comparator) | same relation/probes | same corpus | `accept` (concur_accept=8) |

Implementation artifacts:

- `fixtures/native/base-x-vuln/package.json` pins `base-x` `5.0.0`
- `fixtures/native/base-x-fixed/package.json` pins `base-x` `5.0.1`
- shared Node target wrapper `fixtures/native/basex_codec.js`
- strict reference decoder `fixtures/native/b58_refstrict`
- probes `scripts/agent-eval/gen-basex-homoglyph.sh` (valid Base58 + Unicode homoglyph)
- gate `scripts/check-basex-homoglyph-hunt.sh`

The gate installs pinned versions locally if missing, runs both hunts, asserts defect-direction reject on vulnerable and accept on fixed, and stores logs under `.harness-data/agent-eval/g84-pinned-repro/`.

### Pinned historical candidate queue (G88 follow-on)

Run: 2026-06-26 (#126). After G88 proved the differential vehicle on a published CVE, the next pins are ranked by vehicle fit and credibility. Status is **mapped**, not wired, unless noted.

| # | Target (pin) | Defect | Relation | Severity | Status | Source |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `base-x` npm `<3.0.11` / `5.0.0` | Unicode homoglyph decode bypass | differential | HIGH (CVE-2025-27611) | **Done (G88)** | [NVD CVE-2025-27611](https://nvd.nist.gov/vuln/detail/CVE-2025-27611) |
| 2 | `rust-bitcoin/rust-bech32` pre-#274 fix | accepts witness version 17..31 | differential | low | **Done (G89)** | [issue #274](https://github.com/rust-bitcoin/rust-bech32/issues/274) |
| 3 | `btcsuite/btcutil` pre-#152 fix | bech32 `Encode` accepts uppercase HRP | differential | medium | **Blocked** (Go toolchain) | [issue #152](https://github.com/btcsuite/btcutil/issues/152) |
| 4 | `bitcoinjs-lib` pre-#1750 fix | Taproot v1 program length unchecked | differential | medium | **Blocked** (needs taproot-strict reference; sipa ref accepts witver 16 on short program) | [issue #1750](https://github.com/bitcoinjs/bitcoinjs-lib/issues/1750) |
| 5 | `keefertaylor/Base58Swift` #23 | base58check decode fails on leading `0x00` | differential decode | medium | **Done (G90)** | [issue #23](https://github.com/keefertaylor/Base58Swift/issues/23) |
| 6 | `bitcoinjs-lib` #1537 | bech32 encode throws on version >31 | differential | low | **Blocked** (encode-side; same Node stack as #4) | [issue #1537](https://github.com/bitcoinjs/bitcoinjs-lib/issues/1537) |
| 7 | `cosmos-sdk` pre-#10163 fix | mixed-case bech32 accepted | differential | medium | **Blocked** (Go toolchain) | [issue #10163](https://github.com/cosmos/cosmos-sdk/issues/10163) |
| 8 | `btcsuite/btcd` #1798 | mixed-case `DecodeAddress` breakage | differential | low | **Blocked** (Go toolchain) | [issue #1798](https://github.com/btcsuite/btcd/issues/1798) |
| 9 | `dougal/base58` (Ruby) #8 | leading `0x00` bytes dropped on encode | round_trip | low | **Blocked** (Ruby gem install in harness) | [issue #8](https://github.com/dougal/base58/issues/8) |
| 10 | `dwyl/base58` (Elixir) pre-#5 fix | missing leading `1` for leading zero | round_trip | low | **Blocked** (Elixir not in harness) | [issue #5](https://github.com/dwyl/base58/issues/5) |
| 11 | `keis/base58` #30 | `b58encode_int` drops leading zeros | round_trip | informational | **Skipped** (`relation_gap` by design) | [issue #30](https://github.com/keis/base58/issues/30) |
| 12 | `sipa/bech32` pre-BIP350 / #51 | `q` insertion length-extension | new relation | spec weakness | **Blocked** (needs checksum-strength relation) | [BIP-350](https://github.com/sipa/bips/blob/bip-bech32m/bip-0350.mediawiki) |
| 13 | `1200wd/bitcoinlib` @ `bec99a2` | CompactSize non-minimal at boundaries | round_trip | low | **Done (G86, novel)** | #127, `fixtures/backtest/bitcoinlib-compactsize/CASE.md` |

Excluded from this queue (out of scope or unverified): `secp256k1-node` ECDH CVE (not a codec), `libbase58` zero-byte overflow (sketchy secondary sources only).

**Novel-discovery queue (separate ranking).** Thin unaudited libraries for blind defect yield, not historical CVE pins. Top entries: `petertodd/python-bitcoinlib` VarInt (#320), `KarpelesLab/bech32m`, `pbech32`, `ebellocchia/bip_utils`, `embit`, `btclib`, `ofek/bit`, `pycoin`, `JackalLabs/bech32`, `bs58`. Well-audited flagships (`@scure/base`, maintained `btcd`/`btcutil` for discovery, `NBitcoin`, `libwally-core`) were left off after the PyPI long-tail sweep returned honest null.

**Novel-discovery sweep status.** Run: 2026-06-27 (#126).

| Target | Tier | Surfaces probed | Result |
| --- | --- | --- | --- |
| `pbech32` 0.2.0 (Rust) | thin, single-maintainer | raw bech32/bech32m decode vs sipa reference | **Reject (G91, novel).** Accepts a >90-char valid-checksum bech32m string; reference rejects on the BIP173 length cap. |
| `embit` (Python) | maintained PyPI | witver>16, base58check leading-zero | null (correct on all) |
| `python-bitcoinlib` (Python) | maintained PyPI | witver>16, base58 leading-zero | null (correct on all) |
| `keis/base58` (Python) | maintained PyPI | base58check leading-zero, unicode homoglyph | null (rejects unicode, preserves leading zero) |
| `pycoin` (Python) | maintained PyPI | base58 leading-zero, unicode homoglyph | null (rejects unicode, preserves leading zero) |

Maintained PyPI tier is null on the three known surfaces, a second confirmation of the earlier long-tail null. `KarpelesLab/bech32m` and `JackalLabs/bech32` stay blocked (no Go toolchain); `btclib` blocked (native secp256k1 build fails on py3.14); `bip_utils` blocked (native dep).

**Recommended next pin.** None remaining at low wiring cost. Unblock Go toolchain for #3/#7/#8, or add a taproot-strict reference for #4, or a checksum-strength relation for #12.

### G89 pinned historical repro (rust-bech32 #274)

Run: 2026-06-26 (#126). `bech32` crate `0.12.0` `CheckedHrpstring::validate_segwit` accepts witness version 17..31; `SegwitHrpstring::new` rejects and serves as the fixed comparator on the same pin.

| Target | Relation | Witness | Verdict |
| --- | --- | --- | --- |
| `rust-bech32-vuln` (`validate_segwit` path) | differential vs `bech32m_ref` | `bc13...` witver 17 | `reject`, `reason=target_accepts_reference_rejects`, `target_out=17:...`, `reference_out=REJECT` |
| `rust-bech32-fixed` (`SegwitHrpstring::new`) | differential | same corpus | `accept` (concur_accept=7) |

Gate: `scripts/check-rust-bech32-hunt.sh`. Logs under `.harness-data/agent-eval/g89-pinned-repro/`.

### G90 pinned historical repro (Base58Swift #23)

Run: 2026-06-26 (#126). Base58Swift `2.1.x` drops leading zero bytes on decode; PR #21 head (`06f76eb`) is the fixed comparator revision.

| Target | Relation | Witness | Verdict |
| --- | --- | --- | --- |
| `base58swift-vuln` | differential decode vs PR #21 head | `16L5yRNPTuciSgXGHqYwn9N6NeoKqopAu` | `capability_gap`, `reason=target_rejects_reference_accepts` (under-decode, not over-accept) |
| `base58swift-fixed` | round_trip seed corpus | same probes | `accept` (accepted=6) |

Gate: `scripts/check-base58swift-hunt.sh`. Aggregate gate: `scripts/check-pinned-historical-repros.sh` (G88+G89+G90).

### G91 novel discovery (pbech32 missing BIP173 length cap)

Run: 2026-06-27 (#126). First novel divergence the differential vehicle found on unaudited code with no pre-existing issue, distinct from the historical pins (G88–G90). `pbech32` 0.2.0 is a single-maintainer general-purpose Rust bech32 codec whose `RawBech32` length constraint is `(8, None)`; the source comment notes "BIP173 max is 91" but no upper bound is enforced.

| Target | Relation | Witness | Verdict |
| --- | --- | --- | --- |
| `pbech32_target` (`RawBech32::new`) | differential vs `bech32raw_ref` (sipa raw decode) | 109-char valid-checksum bech32m (`bc1qqqq…hajhhf`) | `reject`, `reason=target_accepts_reference_rejects`, `target_out=b32m:bc:00…`, `reference_out=REJECT` |

The divergence is precisely a missing length cap, not blind acceptance: tampering one checksum character of the same overlong string makes `pbech32` reject, and target and reference agree byte-for-byte on short valid strings. Severity low. Plausibly an intentional relaxation for a general-purpose codec, but it weakens the checksum's bounded error-detection guarantee that the 90-char cap exists to protect, and the vehicle surfaced it blind. Gate: `scripts/check-pbech32-hunt.sh`. Logs under `.harness-data/agent-eval/g91-novel-pbech32/`.

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

Pinned historical repro gates (G88–G90):

```bash
./scripts/check-pinned-historical-repros.sh
```
