# APE target extension follow-on (G54 audit tranche)

Audit note for ADR-014. The ADR verdict **reject** stands as issued. This doc records a resumed falsification pass after cosmocc became available. It does not soften or rewrite the ADR.

Spike date: 2026-06-11 (follow-on).

## Host environment

| Field | Value |
| --- | --- |
| Host | darwin arm64 |
| cosmocc | 14.1.0 from `https://cosmo.zip/pub/cosmocc/cosmocc.zip` under `spike/ape/` |
| APE loader | `cc -O -o /tmp/ape-m1 spike/ape/bin/ape-m1.c` |
| Linux runner | docker (`./scripts/check-linux-runner.sh`) |

## Pre-registered protocol

```bash
./spike/ape/run-g54-followon.sh
```

H1 attempts APE builds of `ngb-extract` and `conf-eval`, runs `./scripts/check-case-fit-rubric.sh`, records wall time.

H2 builds `spike/ape/utf8_cosmo.c` with `-DOVERLONG_OK` as APE, runs native round_trip witness on probe `114816`, compares to `./scripts/agent-eval/metamorphic-verify.sh` on committed `fixtures/metamorphic/utf8_overlong.ngb` via docker ELF.

Freestanding `fixtures/metamorphic/utf8.c` cannot compile with cosmocc (`-nostdlib` unsupported). H2 uses an algorithm-identical cosmopolitan port in `spike/ape/` only.

## Results

### H1 — Harness tooling portability

**PARTIAL.** Both `ngb-extract.ape` and `conf-eval.ape` build. `conf-eval.ape fixtures/input-math/gcd.spec 12 18` prints `6`. `./scripts/check-case-fit-rubric.sh` exits 0 in 615 ms on this host.

The rubric script does not invoke APE-built binaries today. H1 pass criteria from #71 item (2) is not fully met until a gate wires `CONF_EVAL` / `NGB_EXTRACT` env overrides or a dedicated APE rubric script exists.

### H2 — Witness reproducibility across loaders

**PROVEN (single probe).** ELF docker witness:

```
verdict=reject hash=bab50fe2b345 relation=round_trip witness bytes=114816 hex=C080 decode=0 reencode=256
```

APE native witness on the same probe:

```
verdict=reject relation=round_trip witness bytes=114816 hex=C080 decode=0 reencode=256
```

`decode=0` and `reencode=256` match byte-for-byte on the witness fields. Hash prefix differs because APE is not the committed `.ngb` artifact.

### H3 / H4

Unchanged from [`APE-TARGET-SPIKE.md`](APE-TARGET-SPIKE.md). H3 partial ELF-only still holds for `.ngb` parse boundary. H4 kill stands.

## Verdict impact on ADR-014

**No change.** Witness parity on one utf8 probe shows APE can reproduce metamorphic reject semantics natively on macOS. That is evidence for a **tooling** follow-on (Tier 1 in the Justine POV thread), not for extending the verify floor or un-parking G60–G62. H1 remains partial until rubric consumes APE binaries.

## Tranche 2: H1 PROVEN (#85)

`check-input-math-conformance.sh` and `run-linux-elf-capture.sh` gained env seams (`CONF_EVAL`, `NGB_PARSE`, `NGB_EXTRACT`; native default unchanged). `spike/ape/run-h1-ape-rubric.sh` builds `conf-eval`, `ngb-parse`, `ngb-extract` as APE, wraps them in loader shims, and runs the real gate twice.

```
native rc=0 wall_ms=3026  INPUT-MATH-CONFORMANCE OK
ape    rc=0 wall_ms=4145  INPUT-MATH-CONFORMANCE OK
```

**H1: PROVEN.** The full gcd case table (v1/v2 accepts, near-miss split) passes with all three harness tools as APE binaries on macOS arm64, no local C toolchain compile of the tools. Specimens stay Linux ELF via docker by design. This moves the ADR-014 tooling tier from parked to viable; the verify-floor reject is untouched. See the ADR-014 addendum.

## Verification

```bash
./spike/ape/run-g54-followon.sh
./spike/ape/run-h1-ape-rubric.sh
./scripts/check-canonical-drift.sh
```
