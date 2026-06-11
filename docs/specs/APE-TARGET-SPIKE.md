# APE target extension spike (G54, #71)

Falsification study for Cosmopolitan Actually Portable Executable (APE) as a NanoGraph **target extension** beyond Linux ELF + qemu/Docker.

## Host environment

| Field | Value |
| --- | --- |
| Host | darwin (macOS) |
| cosmocc | **not installed** (`which cosmocc` empty) |
| Linux runner | available via `./scripts/check-linux-runner.sh` |

Spike date: 2026-06-11.

## Hypothesis results

### H1 — Harness tooling portability

**INCONCLUSIVE (blocked).** cosmocc was not present on the spike host. `ngb-extract` and `conf-eval` were not built as APE. Cannot compare macOS-native rubric wall time vs Linux baseline without a pinned cosmocc toolchain.

**Recorded command attempt:**

```bash
which cosmocc  # exit 1, not found
```

Fail criteria not met (build did not fail, it was never attempted). Pass criteria not met. Blocked on toolchain install.

### H2 — Witness reproducibility across loaders

**INCONCLUSIVE (blocked).** Requires APE-built equivalents of `utf8.ngb` honest and overlong-bug revision on macOS native loader vs Linux ELF via qemu. No APE binaries were produced in this spike.

### H3 — `.ngb` boundary on APE polyglot bytes

**PARTIAL on Linux ELF slice only.** On the committed Linux ELF specimen `fixtures/metamorphic/utf8.ngb`:

```bash
make -C tools -s bin/ngb-parse
tools/bin/ngb-parse fixtures/metamorphic/utf8.ngb
# ok graph_root_hash=d24928b8741b43786a9674b7f009f6b16f43aed3971092412e2d77c97ac2b040
```

Outcome (a) clean parse with explicit `graph_root_hash` on **Linux ELF**. APE polyglot slice not tested. No I1–I6 violation observed on ELF input.

**Kill not triggered.** No format bump required for ELF slice.

### H4 — Real portability bug observability (G33 bridge)

**REFUTED (kill report).** No FIT candidate mined in this spike pass for a real OS-level serialization defect observable on two loaders without the G33 `BUGGY_TEXTMODE` shim. G33 remains the modeled portability case. cosmopolitan/Knuth-adjacent file-I/O mining did not surface a new witness within spike scope.

Scorecard `fixtures/fit-cases/ape-target-extension.fit` committed with `parked=1`.

## Final verdict

**reject** for verification extension. No evidence that APE adds loader-invariant witness value beyond Linux ELF + existing runner. H1 and H2 blocked on cosmocc. H3 partial on ELF only does not extend the product claim. H4 kill stands.

**Tooling-only note:** Revisit H1 only if cosmocc is pinned and macOS rubric runs are recorded. That would be a follow-on tooling issue, not a verify-floor change.

## Non-goals honored

- No `.ngb` format change.
- No new mandatory CI gate.
- No llamafile/GGUF target.

## Verification

```bash
./scripts/check-canonical-drift.sh
./scripts/score-case-fit.sh fixtures/fit-cases/ape-target-extension.fit
```

Follow-on audit (cosmocc installed): [`APE-TARGET-SPIKE-FOLLOWON.md`](APE-TARGET-SPIKE-FOLLOWON.md).
