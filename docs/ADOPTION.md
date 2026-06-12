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

## Bring your own codec

NanoGraph verifies a **freestanding x86_64 Linux ELF**, not your hosted library source as-is. If your codec lives in normal application C (with libc, no `_start`, no argv driver), you must **transcribe** it into a small freestanding specimen before `mint`.

**Do not** `./nanograph mint c maintainer-home/hex.c` (or your hosted tree path) and expect verify to work. **Start from** `fixtures/templates/icp-hex-specimen.c`, adapt the encode/decode logic, then mint the adapted file.

What that means in practice:

1. Copy your encode/decode logic into a freestanding driver with `enc` and `dec` argv modes (see the templates below).
2. Write a `.req` declaring `relation=round_trip` (or another supported relation), `encode`, `decode`, `reject`, and `wire`.
3. Use `domain=bytes` with `wire=hex` when your wire format is even-length hex strings. You do not need a new hard-coded domain name in the verifier.
4. Mint and verify:

```bash
./nanograph mint c fixtures/templates/icp-hex-specimen.c /tmp/my-hex.ngb
./nanograph verify /tmp/my-hex.ngb fixtures/templates/icp-hex-roundtrip.req
```

Templates (start here, adapt to your codec):

| File | Purpose |
| --- | --- |
| `fixtures/templates/icp-hex-specimen.c` | Freestanding hex codec driver (ICP persona shape) |
| `fixtures/templates/icp-hex-roundtrip.req` | `domain=bytes`, `wire=hex` round_trip request |
| `fixtures/metamorphic/utf8.c` + `utf8.req` | Larger worked example with packed integer wire |

For the full `.req` field list see `docs/specs/METAMORPHIC-RELATIONS.md`. For mint contract details see `docs/specs/LANG-PACKS.md`.

## Verification commands for contributors

```bash
./scripts/check-icp-cli.sh
./scripts/check-icp-adoption-sandbox.sh
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
