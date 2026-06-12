# NanoGraph adoption guide

This guide is for maintainers evaluating NanoGraph on real code.

NanoGraph is a verification pattern over compiled artifacts, not a source-level lint. You define a property in `.req`, run it against `.ngb`, and use accept or reject plus witness output to decide what to fix.

## Who should use this

Best fit:

- codec, parser, or serializer maintainers;
- correctness-critical byte handling;
- cases where expected outputs are costly to curate.

Weak fit:

- ordinary app code with cheap unit-test oracles;
- teams expecting coverage metrics as the main output;
- workflows without a stable runnable artifact.

For ICP rationale and evidence, see `docs/ICP.md`.

## Prerequisites

- macOS or Linux shell;
- `make`;
- a Linux ELF execution path available to repository scripts (native Linux, qemu user-mode, or Docker).

## CLI surface

Use the root CLI entrypoint:

```bash
./nanograph help
```

Current commands:

- `doctor`
- `demo utf8`
- `fit <case.fit>`
- `verify [--expect accept|reject] <candidate.ngb> <request.req>`
- `mint <c|rust|go|zig> ...`

## Minimal workflow

1) Confirm environment:

```bash
./nanograph doctor
```

2) Check candidate fit:

```bash
./nanograph fit fixtures/fit-cases/rust-base64-invalid-last.fit
```

3) Mint a specimen:

```bash
./nanograph mint c fixtures/metamorphic/bswap32.c /tmp/bswap32.ngb
```

4) Verify property:

```bash
./nanograph verify /tmp/bswap32.ngb fixtures/metamorphic/bswap32.req
```

5) Use reject witness output to refine the fix and replay.

## Verification commands for contributors

```bash
./scripts/check-icp-cli.sh
./scripts/check-canonical-drift.sh
```

For full matrix checks:

```bash
./scripts/check-all-proofs.sh
```

## Canonical references

This guide is an entrypoint. Canonical ownership stays in:

- `nanograph.md`
- `docs/CANONICAL.md`
- `docs/specs/NGB-V0.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/NANO-GOALS.md`
- `docs/adr/ADR-021-lang-pack-contract.md`
