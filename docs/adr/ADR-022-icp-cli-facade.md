# ADR-022 — ICP CLI facade over script surface

**Status:** Accepted
**Date:** 2026-06-12
**Goal:** G78 (#110)

## Context

NanoGraph's verification floor is modular and stable (`tools/bin/*`, `.req`, `.ngb`), but ICP-facing usage is fragmented across many script paths. This increases onboarding cost for correctness-critical maintainers who only need the wedge flow (`fit` + `verify` + witness), not the full harness matrix.

`docs/ICP.md` describes adoption as a pattern. The missing piece is a single command surface that preserves floor contracts while reducing reader load.

## Decision

Adopt a thin repo-local CLI facade at `scripts/nanograph` that delegates to existing scripts and tools.

Initial command set:

- `doctor`
- `demo utf8`
- `fit <case.fit>`
- `verify [--expect accept|reject] <candidate.ngb> <request.req>`
- `mint <c|rust|go|zig> ...`

The facade is orchestration only. It does not re-implement relation logic, parser checks, or minter internals.

## Alternatives rejected

- Rewriting the verifier in a new binary command.
  - Rejected because the adjacent lower layer already exists and is proven (`metamorphic-verify.sh` + `tools/bin/*`).
- Keeping raw scripts only.
  - Rejected because ICP onboarding remains unnecessarily expensive for the target user.
- Building a package-manager-distributed CLI first.
  - Rejected because product validation is still in-repo and evidence-driven.

## Consequences

- Existing scripts remain source of truth. The facade is additive and reversible.
- User-facing and onboarding callsites can migrate to `scripts/nanograph` progressively.
- Regression now includes CLI smoke coverage (`scripts/check-icp-cli.sh`).
- Floor boundaries stay unchanged (`NGB-V0`, `.req` schema, tool binaries).

## Kill trigger

If the facade diverges from backend behavior or doubles maintenance cost without measurable onboarding improvement, remove callsite rewires and keep scripts as the only public surface.
