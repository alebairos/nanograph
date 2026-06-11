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

**PROVEN (one run, frozen sidecar).**

| Path | Wall ms | Verdict |
| --- | ---: | --- |
| Hand `.req` | 2383 | `verdict=reject … witness bytes=F hex=46 decode=496 reencode=F0` |
| Sidecar `.req.auto` | 1968 | identical verdict line |

Sidecar recalled `wire=ascii` from the source comment (`wire=ascii` in header). No change to `propose-req.py`.

Both paths dominated by docker Linux runner startup (~2 s), not `.req` authoring. The pass is structural (matching reject + not slower), not a latency win for production agent loops.

### H1 / H2 / H4

Unchanged from [`CANDIDATE-ID-SPIKE.md`](CANDIDATE-ID-SPIKE.md).

## Verdict impact on ADR-015

**No change.** One novel codec under freeze does not justify wiring the sidecar into `check-all-proofs.sh` or un-parking G63–G64. It refutes the claim that H3 was untestable. It does not refute the H1 overfit concern on the original holdout (cosmo_ljson `eq=exact` miss).

## Verification

```bash
./spike/candidate-id/run-h1-h2.sh
./spike/candidate-id/run-h3.sh
./scripts/check-canonical-drift.sh
```
