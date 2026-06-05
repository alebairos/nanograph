#!/usr/bin/env python3
"""Build fixtures/hello_elf.bin and fixtures/hello.ngb.hex (canonical hello)."""
from __future__ import annotations

import argparse
import hashlib
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "fixtures"

HEADER_SIZE = 64
NODE_SIZE = 48
MAGIC = b"NGB\x00"
ARCH_X86_64_LINUX_ELF = 1


def sha256(data: bytes) -> bytes:
    return hashlib.sha256(data).digest()


def build_minimal_elf() -> bytes:
    code = bytes([0xB8, 0x3C, 0x00, 0x00, 0x00, 0x48, 0x31, 0xFF, 0x0F, 0x05])
    e_entry = 0x400078
    ph_off = 64
    ph_num = 1
    ph_entsize = 56
    code_off = ph_off + ph_num * ph_entsize
    code_vaddr = e_entry
    filesz = memsz = len(code)
    align = 0x1000

    hdr = bytearray(64)
    hdr[0:4] = b"\x7fELF"
    hdr[4] = 2
    hdr[5] = 1
    hdr[6] = 1
    hdr[18:20] = struct.pack("<H", 2)
    hdr[20:22] = struct.pack("<H", 0x3E)
    hdr[22:24] = struct.pack("<H", 1)
    hdr[24:32] = struct.pack("<Q", e_entry)
    hdr[32:40] = struct.pack("<Q", ph_off)
    hdr[54:56] = struct.pack("<H", 64)
    hdr[56:58] = struct.pack("<H", ph_num)
    hdr[58:60] = struct.pack("<H", ph_entsize)

    ph = bytearray(56)
    ph[0:4] = struct.pack("<I", 1)
    ph[8:16] = struct.pack("<Q", code_off)
    ph[16:24] = struct.pack("<Q", code_vaddr)
    ph[24:32] = struct.pack("<Q", code_off)
    ph[32:40] = struct.pack("<Q", filesz)
    ph[40:48] = struct.pack("<Q", memsz)
    ph[48:56] = struct.pack("<Q", align)

    return bytes(hdr) + bytes(ph) + code


def pack_ngb(elf: bytes, node_id: int = 1) -> bytes:
    image = elf
    image_len = len(image)
    node_count = 1
    patch_count = 0

    image_off = HEADER_SIZE
    node_off = image_off + image_len
    patch_off = node_off + node_count * NODE_SIZE
    patch_len = 0

    off = 0
    length = image_len
    slice_hash = sha256(image[off : off + length])
    node = struct.pack("<QII32s", node_id, off, length, slice_hash)
    assert len(node) == NODE_SIZE

    hdr = bytearray(HEADER_SIZE)
    hdr[0:4] = MAGIC
    struct.pack_into("<H", hdr, 4, 0)
    struct.pack_into("<H", hdr, 6, ARCH_X86_64_LINUX_ELF)
    struct.pack_into("<I", hdr, 8, 0)
    struct.pack_into("<I", hdr, 12, image_off)
    struct.pack_into("<I", hdr, 16, image_len)
    struct.pack_into("<I", hdr, 20, node_off)
    struct.pack_into("<I", hdr, 24, node_count)
    struct.pack_into("<I", hdr, 28, patch_off)
    struct.pack_into("<I", hdr, 32, patch_count)
    hdr[32:40] = b"\x00" * 8

    hash_input = bytes(hdr[0:32]) + bytes(hdr[40:64]) + image + node
    hdr[32:40] = sha256(hash_input)
    return bytes(hdr) + image + node


def hex_lines(data: bytes) -> str:
    lines = []
    for i in range(0, len(data), 16):
        chunk = data[i : i + 16]
        hexpart = " ".join(f"{b:02x}" for b in chunk)
        lines.append(f"{i:08x}  {hexpart}")
    return "\n".join(lines) + "\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--print-hash", action="store_true")
    ap.add_argument("--write", action="store_true", help="Write fixtures (default)")
    args = ap.parse_args()
    do_write = args.write or not args.print_hash

    elf = build_minimal_elf()
    ngb = pack_ngb(elf)
    root = ngb[32:40]

    if args.print_hash:
        print(root.hex())

    if do_write:
        FIXTURES.mkdir(parents=True, exist_ok=True)
        (FIXTURES / "hello_elf.bin").write_bytes(elf)
        (FIXTURES / "hello.ngb").write_bytes(ngb)
        (FIXTURES / "hello.ngb.hex").write_text(hex_lines(ngb))
        readme = FIXTURES / "README.md"
        readme.write_text(
            f"""# Fixtures (canonical hello)

See [`docs/specs/HELLO-CANONICAL.md`](../docs/specs/HELLO-CANONICAL.md).

| File | Notes |
| --- | --- |
| `hello_elf.bin` | Minimal x86_64-linux ELF, exit(0) |
| `hello.ngb` / `hello.ngb.hex` | Canonical `.ngb` v0 (regenerate with `scripts/build-canonical-hello.py`) |

**graph_root_hash (sha256):** `{root.hex()}`

**image_len:** {len(elf)}  
**node_count:** 1 (`node_id=1`, offset 0, length {len(elf)})
"""
        )
        print(f"wrote fixtures/ (graph_root_hash={root.hex()})")


if __name__ == "__main__":
    main()
