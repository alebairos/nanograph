# ICP maintainer simulation eval (G81)

Live-agent usability probe for the skeptical codec maintainer ICP. A persona cold-starts from `README.md` in an isolated clone and attempts adoption through verifying `maintainer-home/hex.c`. The deliverable is `STALL-REPORT.md`, not a green CI badge.

Bound issue: #115. Refs G78–G80, `docs/ICP.md`.

## Data shapes

### `IcpSimStep` (one line in `STALL-REPORT.md`)

```text
step=<n> surface=<README|ADOPTION|CLI|docs|own-code> action=<command or doc read> verdict=<ok|friction|stall>
note=<one-line candid note>
```

Reading script or tool source to recover missing doc info counts as `friction`. No documented forward path counts as `stall`.

### `IcpSimResult` (final line)

```text
ICP-SIM RESULT completed=<yes|no> first_stall=<step number|none> friction=<count>
```

`completed=yes` requires verifying a property of the persona codec end to end. Running the UTF-8 demo alone does not count.

### `IcpSimBaseline` (`fixtures/icp-sim/baseline.json`)

| Field | Meaning |
| --- | --- |
| `expect.completed` | Exact match when set |
| `expect.first_stall` | Exact match when set |
| `expect.first_stall_not_before` | Fail if `first_stall` is a step number below this threshold (mechanical regression guard) |
| `expect.friction_max` | Fail if friction count exceeds this |

Bump baseline only when the adoption contract intentionally changes (for example after #118/#119 land and `completed=yes` becomes the target).

Prefer threshold guards over exact pins for stochastic live eval. Pin `expect.completed` and `expect.friction_max`. Use `expect.first_stall_not_before` to catch mechanical regressions (steps 1–5). Avoid exact `expect.first_stall` unless reproducing a fixed scripted run.

Reference live run artifact: `fixtures/icp-sim/stall-report-completed-yes.md` (from `run-20260613T023339Z` on main@8e73da3).

`prepare-icp-sim-sandbox.sh` uses `git archive HEAD` then overlays working-tree ICP scripts so acceptance gates match the tree under edit. External clones at a commit see only committed bytes.

## Roles

| Role | Script | CI? |
| --- | --- | --- |
| Sandbox prep | `prepare-icp-sim-sandbox.sh` (archive + ICP overlay) | via `check-icp-sim-sandbox.sh` |
| Scripted adoption | `check-icp-adoption-sandbox.sh` | yes |
| Stall report schema | `check-icp-stall-report.sh` | yes (fixture) |
| Live persona | `run-icp-sim.sh` | no |
| Baseline compare | `check-icp-sim-eval.sh` | no (called by live runner) |

## Deterministic gates

`check-icp-adoption-sandbox.sh` prepares an isolated sandbox and runs the README quick-start path:

1. `./nanograph doctor` (must print `runner=`)
2. `./nanograph demo utf8`
3. `./nanograph fit` smoke
4. `./nanograph verify` accept on `utf8.ngb`
5. `./nanograph verify --expect reject` on `utf8_overlong.ngb` with witness output
6. ADOPTION tutorial mint+verify on `bswap32.c`
7. Maintainer template mint+verify on `fixtures/templates/icp-hex-specimen.c` with `domain=bytes`

This catches mechanical onboarding regressions (#116/#117 class) without an LLM.

## Live eval

```bash
# loads CURSOR_API_KEY from repo-root .env when present
./scripts/agent-eval/run-icp-sim.sh
```

Artifacts land under `.harness-data/agent-eval/icp-sim/run-<timestamp>/` (`stream.jsonl`, `stderr.txt`, `STALL-REPORT.md`).

The live runner uses `--sandbox disabled` so shell commands match a maintainer terminal (Docker/qemu runner access). Cursor agent sandbox would block the runner socket and produce false mechanical stalls.

After a run that intentionally changes the contract:

```bash
./scripts/agent-eval/run-icp-sim.sh --update-baseline
```

Requires `jq`. Removes `first_stall_not_before` and pins exact `completed`, `first_stall`, and `friction_max`.

## Honest scope

The sim detects doc gaps, broken commands, and the freestanding-specimen wall. It is not the ICP kill/confirm signal in `docs/ICP.md` and cannot measure real willingness to adopt.

Findings from the first run (#116–#119) are onboarding and tooling defects, not binary verification catches on target codecs.

## Verification matrix

| Check | When |
| --- | --- |
| `./scripts/check-icp-sim-sandbox.sh` | every `check-all-proofs.sh` |
| `./scripts/check-icp-adoption-sandbox.sh` | every `check-all-proofs.sh` |
| `./scripts/check-icp-stall-report.sh fixtures/icp-sim/stall-report-minimal.md` | every `check-all-proofs.sh` |
| `./scripts/agent-eval/run-icp-sim.sh` | manual / release eval |
| `./scripts/check-canonical-drift.sh` | docs change |
