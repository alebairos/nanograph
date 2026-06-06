# Author sandbox (G16)

Minimal workspace for the live Cursor CLI author. The harness stays outside and applies patches. The author must not read the full repo.

Bound issue: #36. Bound milestone: G16. Decision: [`ADR-003`](../adr/ADR-003-author-sandbox.md).

## Data shapes

### `AuthorSandbox` (materialized tree)

```text
$SANDBOX/
  genesis.ngb          # copy of fixtures/print_42.ngb
  intent.spec          # copy of print_43_stdout.spec (operands only label)
  bin/ngb-parse        # copied binary, not symlink
  bin/nano-probe       # copied binary, not symlink
  author/SKILL.md      # scrubbed skill, sandbox-local paths
  feedback/
    probe_bundle.txt   # empty until harness copies reject feedback
    verdict.txt
  MANIFEST.sha256      # sha256 of every file except itself
```

Max file count: 8. No symlinks. No subdirectories beyond `bin/`, `author/`, `feedback/`.

### `SandboxAllowlist` (harness-only constants)

These values live only in harness scripts. They must not appear in the sandbox tree.

| Constant | Purpose |
| --- | --- |
| `PATCH_OFF=152` | Oracle offset for static gate `--expect-off` |
| `PATCHED_HASH` | Final hash check after accept |
| `ORACLE_SPEC` | Harness path to conf spec for `conf-eval` |

### `IsolationAudit` (post-round check)

Input: `sandbox_dir`, `stream.jsonl` from `agent --output-format stream-json`.

Pass iff no tool read/write/grep/glob path is outside `$SANDBOX` and no forbidden repo tokens appear in the stream.

Forbidden tokens: `fixtures/`, `docs/`, `.cursor/`, `harness-data/`, `print_42_patched`, `patch-fixture`, `NANO-GOALS`, `MICROOP-FLOOR`.

## Scripts

| Script | Role | CI |
| --- | --- | --- |
| `prepare-author-sandbox.sh <dir>` | Materialize allowlisted tree | yes (via check) |
| `audit-author-isolation.sh <sandbox> <stream>` | Parse stream-json for escape reads | yes (synthetic leak case) |
| `check-author-sandbox.sh` | Deterministic gate | yes |
| `run-live-agent-loop.sh` | Uses `$SANDBOX` as `--workspace` | no (opt-in live) |

## Harness wiring

1. `prepare-author-sandbox.sh "$WORK/author-sandbox"` at loop start.
2. Author invoke: `agent -p --trust --workspace "$SANDBOX" --sandbox enabled`.
3. Prompt references `genesis.ngb`, `intent.spec`, `author/SKILL.md` only.
4. Harness keeps `$WORK/genesis.ngb` for `ngb-patch`. Sandbox `genesis.ngb` is read-only context.
5. On auditor reject, copy `probe_bundle` and `verdict` into `$SANDBOX/feedback/`.
6. Persist each `author_stream_rN.jsonl` under `.harness-data/agent-eval/live-agent/`.
7. Run `audit-author-isolation.sh` after every author round. Fail the loop on violation.

## Scrubbed skill

Source: `scripts/agent-eval/sandbox/live-ngb-author-SKILL.md`.

Rules:

- Paths are `bin/ngb-parse`, `bin/nano-probe`, not `tools/bin/`.
- No numeric `patch_off` or `patch_pairs` examples.
- Author discovers offset via `disassemble`; computes digit from `intent.spec` operands.

Repo skill `.cursor/skills/live-ngb-author/SKILL.md` remains for editor use. Live eval uses the sandbox copy only.

## Verification

Deterministic (CI):

```bash
./scripts/check-author-sandbox.sh
```

Opt-in live probe:

```bash
./scripts/agent-eval/run-live-agent-loop.sh --with-static-gate
```

Expect isolation audit pass and stream persisted under `.harness-data/agent-eval/live-agent/`.

## Depends on

- G13 [`LIVE-AGENT-EVAL.md`](LIVE-AGENT-EVAL.md)
- G15 operational-error matrix (`--expect-off`, `--expect-new`)
