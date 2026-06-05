## Problem

Hello P1 static exists. Concept is not fully proven until pack/parse reproduces the golden `.ngb` and the ELF runs (P2–P3).

## Milestone

Bound milestone: M2

## Acceptance

- [x] `tools/ngb-pack` reads `fixtures/hello_elf.bin`, writes bytes matching `fixtures/hello.ngb`
- [x] `tools/ngb-parse` validates I1–I6 on golden file
- [x] `scripts/check-ngb-roundtrip.sh` passes
- [x] `scripts/check-hello-proof.sh` passes P1–P3 (P3 on linux CI or docker)
- [x] GitHub Actions workflow runs proof on ubuntu

## Verification

- [x] `./scripts/check-ngb-roundtrip.sh`
- [x] `./scripts/check-hello-proof.sh`

## Nano goal

G1 from [`docs/specs/NANO-GOALS.md`](../../docs/specs/NANO-GOALS.md).
