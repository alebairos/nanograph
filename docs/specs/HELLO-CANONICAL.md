# Canonical Hello, World

The first proof that NanoGraph v3 is sound is not a compiler. It is one frozen **hello** artifact with a rerunnable proof ladder.

All milestones **M1–M3** serve this artifact. Do not add a second hello variant without an ADR.

## Artifacts

| File | Role |
| --- | --- |
| `fixtures/hello_elf.bin` | Minimal x86_64-linux ELF, `exit(0)` only |
| `fixtures/hello.ngb.hex` | Canonical `.ngb` v0 bytes (M1 golden) |
| `fixtures/hello.ngb` | Same bytes, binary form (M2 packer must reproduce) |
| `fixtures/hello.audit-log.golden` | Expected `nano-probe audit-log` stdout (M3) |

## Proof ladder

| Layer | ID | Milestone | Claim | Check |
| --- | --- | --- | --- | --- |
| Static | P1 | M1 | Bytes match `NGB-V0.md` layout and documented `graph_root_hash` | `scripts/build-canonical-hello.py` + `check-hello-proof.sh` P1 |
| Structural | P2 | M2 | Pack/parse roundtrip; invariants I1–I6 | `check-ngb-roundtrip.sh` |
| Behavioral | P3 | M2 | ELF in the image runs and exits 0 | `check-hello-proof.sh` P3 (linux or qemu-x86_64) |
| Audit | P4 | M3 | Post-hoc audit output is deterministic | `check-probe-audit-log.sh` |

P1 is the concept proof before tools exist. P3 is the human-visible “hello runs” proof. P4 is the v3 audit story.

## graph_root_hash

Recorded in [`fixtures/README.md`](../../fixtures/README.md) after generation. Recompute with:

```bash
python3 scripts/build-canonical-hello.py --print-hash
```

## Out of scope for hello

- Printing `"Hello, world\\n"` (exit-only keeps ELF tiny and auditable)
- NanoLang source (`.n`) as authority
- Patch-chain edits on genesis hello (patch_count = 0)
