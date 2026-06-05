# `.ngb` v0 (NanoGraph container)

Executable spec target for **M1**. Implementations must match this layout and golden fixtures, not prose in `nanograph.md`.

## Design stance (v3)

- Single canonical artifact per graph version (no sidecar JSON manifest).
- Agents edit facts; humans use **NanoProbe** post-hoc (M3+).
- Parse all untrusted bytes at the boundary; trust nothing inside without validation.

## File layout (little-endian)

```text
┌ Header 64 bytes ────────────────────────┐
│ magic[4]     "NGB\0"                    │
│ version_u16  0                          │
│ arch_id_u16  1 = x86_64-linux-elf       │
│ flags_u32    0                          │
│ image_off_u32                           │
│ image_len_u32                           │
│ node_off_u32                            │
│ node_count_u32                          │
│ patch_off_u32                           │
│ patch_count_u32                         │
│ graph_root_hash[32]  SHA-256 canonical  │
│ reserved[8]                             │
├ Image (image_len bytes) ────────────────┤
│ Raw ELF object (ET_EXEC or ET_DYN POC)  │
├ Node table (node_count × 48 bytes) ───┤
│ node_id_u64                             │
│ offset_u32  offset into image           │
│ length_u32                              │
│ content_hash[32]  SHA-256(image slice)  │
├ Patch log (patch_count × variable) ───┤
│ See patch record below (may be empty)   │
└─────────────────────────────────────────┘
```

### Patch record (v0, fixed 128 bytes header + delta)

| Field | Size | Notes |
| --- | --- | --- |
| patch_id_u64 | 8 | Stable id |
| parent_graph_hash | 32 | Zero hash if genesis |
| precondition_hash | 32 | Must match prior graph_root |
| delta_off_u32 | 4 | Offset in image |
| delta_len_u32 | 4 | Max 4096 in v0 |
| agent_sig | 64 | Ed25519; zeros allowed in M2 fixtures |
| timestamp_u64 | 8 | Unix seconds |

Delta bytes follow the header immediately (delta_len).

## Canonical `graph_root_hash`

SHA-256 over concatenation, in order:

1. Header bytes 0–31 and 40–63 (exclude `graph_root_hash` field bytes 32–39)
2. Image bytes
3. Node table bytes
4. Patch log bytes (headers + deltas)

Implementations must document any change in a version bump.

## Invariants (boundary checks)

| ID | Rule |
| --- | --- |
| I1 | `magic` and `version` recognized |
| I2 | All sections within file bounds |
| I3 | Each node `[offset, offset+length)` ⊆ image |
| I4 | `content_hash` matches image slice |
| I5 | `node_id` unique |
| I6 | Patch `precondition_hash` chain consistent when `patch_count > 0` |

## Node IDs

v0 uses `node_id_u64` only in the binary. Tools may print `#instr_<hex>` as `node_id` formatted in lowercase hex without prefix in the file.

## Fixtures (M1)

- `fixtures/hello.ngb` — packed from minimal x86_64 ELF (added in M2; hex dump documented in M1 README under `fixtures/README.md`)
