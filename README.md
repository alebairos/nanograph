# NanoGraph

NanoGraph is an execution-grounded verification pattern for correctness-critical compiled code.

The core artifact is a binary graph container (`.ngb`) plus a language-neutral verification request (`.req`). The verifier checks properties against the compiled artifact and returns either:

- `verdict=accept`, or
- `verdict=reject` with a concrete byte-level witness.

This is built for cases where expected outputs are expensive to hand-author and silent bugs are costly.

## Who it is for (ICP)

The primary user is a maintainer of codec, parser, serializer, or similar boundary-critical logic.

Good fit:

- The oracle is hard to write by hand.
- The bug can survive normal tests silently.
- A property is easy to state as a relation.

Poor fit:

- Ordinary application code with cheap expected outputs.
- Teams that only want coverage percentages.
- Cases where no stable runnable artifact is available.

See the full ICP statement in `docs/ICP.md`.

## What NanoGraph is and is not

NanoGraph is a verification pattern with strong local proof tooling.

NanoGraph is not a full bug-finding product yet. Blind detection is bounded and documented in `docs/specs/PROBE-GENERATOR-SPIKE.md`.

## Quick start

Prerequisites:

- macOS or Linux shell.
- `make`.
- Docker or another Linux ELF runner path used by repo scripts.

From repo root:

```bash
./nanograph doctor
```

Run the product wedge demo:

```bash
./nanograph demo utf8
```

Score candidate fit:

```bash
./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit
```

Verify an artifact directly:

```bash
./nanograph verify fixtures/metamorphic/utf8_overlong.ngb fixtures/metamorphic/utf8.req
```

Mint an artifact through a language pack:

```bash
./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb
```

## Adoption path

1. Confirm fit with `nanograph fit`.
2. **Transcribe** your codec into a freestanding specimen if it is not already one (see `docs/ADOPTION.md`, section "Bring your own codec").
3. Define a property in `.req` (templates under `fixtures/templates/`).
4. Mint a specimen (`nanograph mint ...`).
5. Run `nanograph verify`.
6. Use reject witnesses to drive fixes and backtests.

For language-pack details see `docs/specs/LANG-PACKS.md`.
For onboarding flow details see `docs/ADOPTION.md`.

## Verification commands

Focused checks:

```bash
./scripts/check-icp-cli.sh
./scripts/check-lang-packs.sh
./scripts/check-canonical-drift.sh
```

Full repository proof matrix:

```bash
./scripts/check-all-proofs.sh
```

## Canonical docs

Do not fork product semantics in this README. This file is an entrypoint only.

- Concept and philosophy: `nanograph.md`
- Canonical doc map: `docs/CANONICAL.md`
- Format spec: `docs/specs/NGB-V0.md`
- Architecture map: `docs/specs/ARCHITECTURE.md`
- Product proof program: `docs/specs/PRODUCT-PROOF.md`
- Goals ledger: `docs/specs/NANO-GOALS.md`
- Lang-pack contract: `docs/adr/ADR-021-lang-pack-contract.md`

## Current status

Technical milestones M0-M7 are complete.

Product proof ladder P01-P20 is complete as infrastructure.

Current work is adoption hardening and evidence-led scope decisions tracked in `docs/specs/NANO-GOALS.md`.
