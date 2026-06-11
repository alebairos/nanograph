# Candidate-ID sidecar follow-on (G55 audit tranche)

Audit note for ADR-015. The ADR verdict **skill-only** stands as issued. This doc records H3 under a frozen sidecar. It does not soften or rewrite the ADR.

Spike date: 2026-06-11 (follow-on).

## Freeze record

| Artifact | SHA256 |
| --- | --- |
| `spike/candidate-id/propose-req.py` | `c406528b8da4a1ecf8a495d15eba666dd417e2191149ef152b5585cc6574a8ef` |

Canonical copy: `spike/candidate-id/FROZEN.sha256`. Any sidecar edit requires a new freeze line and a new follow-on tranche.

## Pre-registered H3 task

Novel holdout codec `spike/candidate-id/h3-nibbles/h3_nibbles.c` with `ODD_LEN_OK` bug class (odd-length hex padding, analogous to utf8 overlong acceptance).

Hand `.req` committed **before** sidecar run:

```
spike/candidate-id/h3-nibbles/h3_nibbles.req
```

Pass criteria from #72 H3: sidecar path reaches `verdict=reject` with matching witness hex in less or equal wall time than the hand path on one controlled run.

## Protocol

```bash
./spike/candidate-id/run-h3.sh
```

Supporting scripts (spike-only, no `tools/` changes):

- `spike/candidate-id/h3-roundtrip-verify.sh` — round_trip with `wire=ascii` probes `00 41 FF F`
- mint via `./scripts/mint-one-elf.sh … -DODD_LEN_OK`

## Results

### H3 — Agent-loop latency

**PROVEN (frozen sidecar, corrected criterion).**

The first protocol gated on end-to-end wall time (hand vs sidecar verify path). A rerun on identical committed inputs flipped that clause PROVEN → REFUTED (1968 ms vs 2383 ms, then 2367 ms vs 2224 ms). Docker runner startup noise dominates both paths, so wall-time comparison cannot gate. The protocol now gates on verdict equivalence plus bounded authoring cost (`propose-req.py` ≤ 1000 ms).

| Run | Verdicts | Authoring ms |
| --- | --- | ---: |
| 1 | identical reject `bytes=F hex=46 decode=496 reencode=F0` | 40 |
| 2 | identical reject, same witness | 38 |

Sidecar recalled `wire=ascii` from the source comment header. No change to `propose-req.py` (freeze hash held across all runs).

Pre-registration is enforced by `run-h3.sh`. It aborts unless the freeze record, sidecar, and hand `.req` are committed and clean, and it prints the commit hashes in the run log.

### H1 / H2 / H4

Unchanged from [`CANDIDATE-ID-SPIKE.md`](CANDIDATE-ID-SPIKE.md).

## Tranche 2: adversarial H3 on a mined codec (#85)

Setup removed the two weaknesses of tranche 1. The codec is mined (`fixtures/fit-cases/go-base64-strict-padding.fit`, golang/go #15656, parent `56b5546b` / fix `87b1aaa3`). The hand `.req` was authored from the scorecard and the base64 driver contract only, and committed (`9b60fde`) before any specimen source existed. The specimen was transcribed by a separate delegate that never read the hand `.req` and was barred from key=value comment hints. Sidecar freeze hash unchanged throughout.

Pre-declared two-variant protocol (in the variant A commit message, before any run):

| Variant | Source | Result |
| --- | --- | --- |
| A (blind) | No relation named anywhere in prose | **REFUTED.** `propose-req.py` raises `no relation inferred`; sidecar cannot propose at all |
| B (house style) | One capnproto-style oracle line added (`round_trip: enc(dec(b)) == b …`) | **PROVEN.** Auto `.req` byte-exact vs hand (field order included); verdicts identical: `reject … bytes=iYV= hex=6959563d decode=8985 reencode=iYU=`; authoring 39 ms |

The boundary is now sharp. The frozen sidecar recalls a separately-authored mined specimen exactly when the source names its relation in prose, which every committed specimen in `fixtures/metamorphic/` does. On a source that does not, it fails closed (error, not a wrong `.req`).

## Tranche 3: the four remaining mined specimens (#87)

Same protocol as tranche 2 with house-style headers from the start; the variant-A fail-closed result is established and was not retested. All four hand `.req` files were committed (`110999f`) before any specimen source existed. Each specimen was transcribed by a separate parallel delegate barred from `.req` files and key=value hints (hint grep 0/4). Sidecar freeze hash unchanged (`9180e99` lineage). The spike verifier gained a `value_oracle` branch (`PROBES` as `input:expected` pairs); the round_trip branch reproduced the tranche 2 witness unchanged after the refactor.

| Specimen | Scorecard | Relation | Bug flag | Recall | Buggy verdict | Authoring |
| --- | --- | --- | --- | --- | --- | --- |
| `zig_adler32` | zig-std-adler32-large | value_oracle | `WRONG_INDEX` | byte-exact | reject (`want=3857828882 got=235750319` on a 5553-byte vector; oracle = python `zlib.adler32`) | 41 ms |
| `go_hex_decode` | go-hex-decode-dst | value_oracle | `ZERO_ON_OVERFLOW` | byte-exact | reject (`want=0011223344556677 got=REJECT` on dst overflow) | 41 ms |
| `miniz_init_tree` | miniz-inflate-huffman | value_oracle | `LAX_TREE` | byte-exact | reject (incomplete tree `0102`: `want=REJECT got=0101…`) | 74 ms |
| `zigimg_gif_lzw` | zigimg-gif-lzw-overflow | round_trip | `NO_CODE_LIMIT` | byte-exact | reject (no-clear overflow stream, 5414 packed bytes, decodes then re-encodes differently) | 113 ms |

All four honest builds accept the same probe sets (`matched=2/4/4`, `accepted=1`).

One fix round was used, on the LZW specimen only. Its decode input buffer was 4096 bytes while a no-clear overflow stream needs ~5.5 KB, so the guarded path was unreachable and both builds were behaviorally identical over the expressible probe space. The cap was bumped to 8192 (mechanical, prose untouched, committed before the run). The overflow probe was generated by a bit-level simulator of the decoder's width schedule, not by hand.

H3 is now 5/5 on mined specimens under house-style prose. Every mapped scorecard from the candidate list has been executed.

## Verdict impact on ADR-015

**No change.** Five recalls under freeze sharpen the tranche 2 boundary but do not touch the original H1 holdout miss (cosmo_ljson `eq=exact`), and the prose dependency stands: recall is conditional on the source naming its relation in corpus convention. Wiring the sidecar into `check-all-proofs.sh` or un-parking G63–G64 remains unjustified by this evidence alone.

## Verification

```bash
./spike/candidate-id/run-h1-h2.sh
./spike/candidate-id/run-h3.sh
./scripts/check-canonical-drift.sh
```
