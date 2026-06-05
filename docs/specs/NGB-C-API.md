# NGB C API (embedder surface)

Public headers live under `tools/ngb/` and `tools/probe/`. CLI binaries are thin wrappers.

## Core (`tools/ngb/ngb.h`)

| Function | Role |
| --- | --- |
| `ngb_pack_elf` / `ngb_pack_elf_nodes` | Build genesis `.ngb` from ELF + node slices |
| `ngb_parse_validate` | I1–I6 boundary validation |
| `ngb_apply_patch` | Append precondition-gated patch |
| `ngb_validate_patch_chain` | I6 only (partial graph replay) |
| `ngb_fill_root_hash` | Canonical `graph_root_hash` at header+32 |
| `ngb_root_hash_hex` | Hex digest helper |
| `ngb_*_elf_build` | Canonical program builders |

## Ownership

- `ngb_pack_elf*`, `ngb_apply_patch` return malloc'd buffers; caller `free()`s.
- Input slices are borrowed; not retained after return.

## Errors (`NgbStatus`)

| Code | String | When |
| --- | --- | --- |
| `NGB_OK` | `ok` | Valid |
| `NGB_ERR_I1_MAGIC` | `I1:magic` | Bad magic/version |
| `NGB_ERR_I2_BOUNDS` | `I2:bounds` | Layout overflow |
| `NGB_ERR_I3_NODE_RANGE` | `I3:node_range` | Node or delta OOB |
| `NGB_ERR_I4_NODE_HASH` | `I4:node_hash` | Slice hash mismatch |
| `NGB_ERR_I5_NODE_DUP` | `I5:node_dup` | Duplicate node id |
| `NGB_ERR_I6_PATCH_CHAIN` | `I6:patch_chain` | Patch precondition chain |
| `NGB_ERR_ROOT_HASH` | `root_hash` | Stored hash drift |

`ngb_status_str()` maps enum to stable tokens for JSON (`ngb-parse --json`).

## Thread safety

No global mutable state. Functions are reentrant if callers do not alias output buffers.

## Probe (post-hoc, `tools/probe/`)

| Entry | CLI |
| --- | --- |
| `probe_audit_log` | `nano-probe audit-log` |
| `probe_diff` | `nano-probe diff` |
| `probe_disassemble` | `nano-probe disassemble` |
| `probe_trace` | `nano-probe trace` |

Probe reads validated `.ngb` only; does not mutate graphs.

## Review checklist

- [ ] New exports added to this doc and `ngb.h`
- [ ] Invariant strings stable for agent JSON parsing
- [ ] Golden proofs updated when canonical bytes change
