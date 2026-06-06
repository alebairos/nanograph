# ADR-003 — Isolated author sandbox for live eval

**Status:** Accepted
**Date:** 2026-06-05
**Goal:** G16 (issue #36)

## Context

G13 proved a live Cursor CLI author can complete the two-agent loop. G14 attempted blind falsification of retry reduction. The skill leak was removed, but the author still ran with `--workspace $ROOT`. The answer and oracle constants appear in roughly eighteen other repo files. G14 was inconclusive, not because the gates failed, but because the author could read the repo.

The operational-error matrix (G15) proves static gates reject bad patches deterministically. It does not prove the live author is isolated from repo leakage.

## Decision

Materialize a **minimal author sandbox** before each live round. The Cursor CLI author runs with `--workspace $SANDBOX` only. The harness stays outside, applies `ngb-patch`, runs the auditor, and copies reject feedback back into the sandbox.

Isolation is enforced two ways:

1. **Structural.** Allowlisted files only. Copied binaries, no symlinks, scrubbed skill, no oracle literals in tree.
2. **Audited.** `audit-author-isolation.sh` scans persisted `stream-json` for tool paths outside the sandbox.

## What we are not building

- No Linux `bwrap` or Docker in v0. Copy-only sandbox is sufficient for the first honest live probe.
- No Wasm or remote sandbox. Local minimal tree matches the harness contract.
- No change to the auditor or static gate semantics. G15 matrix stays as-is.

## Why the adjacent lower layer is insufficient

`--workspace $ROOT` with prompt forbids is policy, not proof. The agent can still read any repo path the CLI allows. A copied allowlist tree plus stream audit is the smallest mechanism that makes leakage falsifiable.

## Design

- `AuthorSandbox` shape in [`AUTHOR-SANDBOX.md`](../specs/AUTHOR-SANDBOX.md).
- `prepare-author-sandbox.sh` builds the tree from genesis fixture, intent spec, and two probe binaries.
- `run-live-agent-loop.sh` switches author workspace to `$SANDBOX`, persists streams, runs isolation audit each round.
- `check-author-sandbox.sh` gates manifest completeness, forbidden-string absence, and synthetic leak rejection in CI.

Harness-only constants (`PATCH_OFF`, `PATCHED_HASH`, oracle spec path) never enter the sandbox.

## Evidence target

| Check | Expected |
| --- | --- |
| `check-author-sandbox.sh` | pass in `check-all-proofs.sh` |
| Live probe (opt-in) | accept in ≤5 rounds with zero isolation violations |
| G14 re-run (optional) | Compare rounds with sandbox vs pre-G16 logs |

A live probe that still accepts in one round does not re-open retry reduction. It only proves the author no longer has repo-wide read access.

## Consequences

- Live eval logs become auditable for path escape.
- Future blind studies can treat sandbox isolation as a controlled variable.
- Repo skill and sandbox skill diverge. Sandbox skill is the source of truth for live eval.
