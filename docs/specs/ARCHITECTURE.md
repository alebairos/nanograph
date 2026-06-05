# Implementation architecture

Maps **code in this repo** to layers. Philosophy stays in [`nanograph.md`](../../nanograph.md). Bytes stay in [`NGB-V0.md`](NGB-V0.md).

## Layer model

| Layer | Role | Path (target) |
| --- | --- | --- |
| L0 | Concept / constraints | `nanograph.md` |
| L1 | Format spec | `docs/specs/NGB-V0.md`, `fixtures/` |
| L2 | Pack + parse (executable spec) | `tools/ngb-pack/`, `tools/ngb-parse/` |
| L3 | Probe (human discovery) | `tools/nano-probe/` |
| L4 | Agent patch CLI | deferred M4+ |
| L5 | Micro-arch validate | deferred; external sim only with ADR |

## Adjacent contracts

| From | To | Contract |
| --- | --- | --- |
| Agent / harness | L1 | Read `NGB-V0.md`; do not invent fields |
| L2 packer | ELF | Read-only ET_* image; labels from objdump/llvm-objdump |
| L2 parser | L1 | Reject illegal states at parse; trust nothing |
| L3 probe | L2 parser | Read-only; deterministic stdout bytes |

## Data shapes (names only)

- `NgbHeader` — 64-byte fixed header
- `NgbNode` — 48-byte node row
- `NgbPatchHeader` — 128-byte patch header + variable delta
- `ParseError` — boundary violation with invariant id (I1–I6)

## Harness (meta)

| Piece | Path |
| --- | --- |
| Loop state | `.harness-data/loop_state.json` |
| Memory | `.harness-data/memory/` |
| Session | `scripts/harness-session-start.sh` |
