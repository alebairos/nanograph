# Nano goals (decided)

Ordered goals for NanoGraph v3. Each canonical program gets the same proof ladder (static → structural → behavioral → audit). No `.n` source authority yet.

## Now

| ID | Goal | Milestone | Why now |
| --- | --- | --- | --- |
| G1 | **Finish hello** P2 pack/parse + P3 run | M2 | Without tools, P1 is faith only |
| G2 | **Hello audit** P4 `audit-log` | M3 | Proves post-hoc v3 audit path |

## Next canonical program (your 1+1 joke, taken seriously)

| ID | Goal | Milestone | Artifact |
| --- | --- | --- | --- |
| G3 | **`add_two`** | M4 | x86_64 ELF: `1+1`, exit code **2** (not stdout) |

`add_two` is the smallest step that proves the graph models **more than one instruction** and a **computable result** auditors can see without a string table.

| Property | hello | add_two |
| --- | --- | --- |
| Instructions | ~1 meaningful (exit) | mov + add + exit (3 nodes min) |
| Observable | exit 0 | exit 2 |
| patch_count | 0 (genesis) | 0 until G5 |
| Proves | container + run | multi-node + semantics |

No `"Hello, world\n"` in G3. Printing is G7 at earliest (needs write syscall + data section). Boring on purpose.

## After add_two

| ID | Goal | Milestone | Notes |
| --- | --- | --- | --- |
| G4 | **probe disassemble** on hello + add_two | M4 | Human discovery; overlay `#instr_*` |
| G5 | **One signed graph patch** on add_two | M5 | Precondition hash + delta; patch log non-empty |
| G6 | **probe diff** genesis → patched | M5 | Byte/node accurate |
| G7 | **print_42** (optional) | M6+ | write syscall; only if G5 stable |

## Explicitly not next

- NanoLang syntax or compiler
- Cycle-accurate `probe verify` / gem5
- Multi-arch
- v2 JSON audit manifest inside `.ngb`
- Agent-facing patch CLI before human pack/parse/probe trust hello + add_two

## Issue mapping (suggested)

| GitHub issue | Binds |
| --- | --- |
| #3 | G1 M2 hello tools |
| #4 | G2 M3 probe audit-log |
| #5 | G3 M4 add_two canonical |
| #6 | G5–G6 patch + diff |

Open issues one at a time. Do not umbrella G1–G6.
