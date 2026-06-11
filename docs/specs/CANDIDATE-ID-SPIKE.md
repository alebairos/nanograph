# Candidate-ID sidecar spike (G55, #72)

Falsification study for a language-aware sidecar at the ADR-007 seam. NanoGraph verify stays blind to source. The sidecar only proposes `.req` files.

## Methodology

Prototype lives under `spike/candidate-id/`. No imports into `tools/` or `metamorphic-verify.sh`.

Holdout corpus (pre-registered in #72):

| Specimen | Hand `.req` | `.ngb` for H2 |
| --- | --- | --- |
| utf8 | `fixtures/metamorphic/utf8.req` | `fixtures/metamorphic/utf8.ngb` |
| leb128 | `fixtures/metamorphic/leb128.req` | `fixtures/backtest/leb128/leb128_rev1.ngb` |
| capnproto_base64 | `fixtures/metamorphic/capnproto_base64.req` | `fixtures/backtest/capnproto-base64/capnproto_base64_rev1.ngb` |
| wabt_leb128 | `fixtures/metamorphic/wabt_leb128.req` | `fixtures/backtest/wabt-leb128/wabt_leb128_rev1.ngb` |
| cosmo_ljson | `fixtures/metamorphic/cosmo_ljson.req` | `fixtures/backtest/cosmo-ljson/cosmo_ljson_rev1.ngb` |

Command:

```bash
./spike/candidate-id/run-h1-h2.sh
```

Sidecar implementation: `spike/candidate-id/propose-req.py` (comment and `real_start` heuristics only).

## Hypothesis results

### H1 — Round-trip pair recall

**PROVEN (4/5).** Threshold was ≥4/5.

| Case | Match | Notes |
| --- | --- | --- |
| utf8 | yes | |
| leb128 | yes | |
| capnproto_base64 | yes | `wire=ascii` from filename heuristic |
| wabt_leb128 | yes | |
| cosmo_ljson | no | Spurious `eq=exact` field. Relation and mode match. |

### H2 — Verdict equivalence

**PROVEN.** On all five holdout `.ngb` files, sidecar `.req.auto` yields byte-identical `metamorphic-verify.sh` verdict lines to the hand `.req` when H1 matched. On cosmo_ljson, verdicts match after relation/mode alignment despite the extra `eq` key in auto output.

### H3 — Agent-loop latency

**INCONCLUSIVE.** Holdout task is already instant for both hand and sidecar paths on this host. No controlled novel-codec edit was run. Wall time dominated by Linux runner startup, not `.req` authoring.

### H4 — Boundary independence

**PROVEN.** Sidecar is entirely under `spike/candidate-id/`. Zero changes to `metamorphic-verify.sh` or `tools/` for sidecar logic.

## Auto `.req` artifacts

Committed twins for diff review:

- `fixtures/metamorphic/*.req.auto` (five holdout files)

## Final verdict

**skill-only.** Static heuristics on freestanding C drivers recall 4/5 hand `.req` shapes and preserve verdicts, but the miss mode is format drift (`eq=exact` emission) and the v0 scope is comment or filename hints only. Worth documenting as an external agent skill, not wiring into `check-all-proofs.sh`. Follow-on G63–G64 stays parked unless a live agent loop shows H3 pass on a novel codec.

## Verification

```bash
./spike/candidate-id/run-h1-h2.sh
./scripts/check-canonical-drift.sh
```

Follow-on audit (H3 frozen sidecar): [`CANDIDATE-ID-SPIKE-FOLLOWON.md`](CANDIDATE-ID-SPIKE-FOLLOWON.md).
