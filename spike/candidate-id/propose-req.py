#!/usr/bin/env python3
"""Language-aware sidecar v0: propose VerificationRequest from freestanding driver .c."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def domain_from_stem(stem: str) -> str:
    return stem


def infer_relation(text: str) -> str | None:
    for pat in (
        r"relation=([a-z_]+)",
        r"\b(round_trip|value_oracle|involution|flow_composition|cmp_order|"
        r"size_monotone|conserve_popcount|linear_xor|range_coverage)\b",
    ):
        m = re.search(pat, text, re.I)
        if m:
            return m.group(1).lower()
    return None


def infer_modes(text: str) -> tuple[str | None, str | None, str | None]:
    encode = decode = mode = None
    if re.search(r"mode\[0\]\s*==\s*['\"]e", text) or re.search(
        r"\benc\s+<", text
    ):
        encode = "enc"
    if re.search(r"mode\[0\]\s*==\s*['\"]d", text) or re.search(
        r"\bdec\s+<", text
    ):
        decode = "dec"
    if re.search(r"mode\[0\]\s*==\s*['\"]f", text) and "flow" in text:
        mode = "flow"
    if re.search(r"mode\[0\]\s*==\s*['\"]c", text):
        mode = "cmp"
    if re.search(r"mode\[0\]\s*==\s*['\"]r", text) and "reverse32" in text:
        mode = "rev"
    if re.search(r"mode\[0\]\s*==\s*['\"]s", text) and "s2u" in text:
        mode = "s2u"
    if re.search(r"mode\[0\]\s*==\s*['\"]d", text) and "value_oracle" in text.lower():
        decode = decode or "dec"
        mode = mode or "dec"
    return encode, decode, mode


def infer_wire(text: str, stem: str) -> str | None:
    if "base64" in stem:
        return "ascii"
    if "wire=hex" in text.lower() or re.search(
        r"hex-decode|parse_hex|wire is the byte", text, re.I
    ):
        return "hex"
    if "wire=ascii" in text.lower() or re.search(r"wire=ascii|base64 string", text, re.I):
        return "ascii"
    return None


def infer_reject(text: str) -> str | None:
    m = re.search(r'#define\s+REJECT\s+(\d+)', text)
    if m:
        return m.group(1)
    if 'print_str("REJECT' in text or "REJECT\\n" in text:
        return "REJECT"
    return None


def propose_req(source: Path) -> dict[str, str]:
    text = read_text(source)
    domain = domain_from_stem(source.stem)
    relation = infer_relation(text)
    encode, decode, mode = infer_modes(text)
    wire = infer_wire(text, source.stem)
    reject = infer_reject(text)

    if not relation:
        raise ValueError(f"no relation inferred from {source}")

    out: dict[str, str] = {
        "relation": relation,
        "entry": "argv_mode",
        "domain": domain,
        "eq": "exact",
    }
    if relation == "value_oracle" and decode and not encode:
        out["mode"] = decode
    else:
        if encode:
            out["encode"] = encode
        if decode:
            out["decode"] = decode
        if mode:
            out["mode"] = mode
    if wire:
        out["wire"] = wire
    if reject:
        out["reject"] = reject
    if relation == "flow_composition":
        out["max_total"] = "64"
    return out


def format_req(fields: dict[str, str]) -> str:
    order = (
        "relation",
        "entry",
        "encode",
        "decode",
        "mode",
        "domain",
        "reject",
        "eq",
        "wire",
        "max_total",
    )
    lines = []
    for key in order:
        if key in fields:
            lines.append(f"{key}={fields[key]}")
    return "\n".join(lines) + "\n"


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: propose-req.py <source.c> <out.req>", file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    dest = Path(sys.argv[2])
    fields = propose_req(source)
    dest.write_text(format_req(fields), encoding="utf-8")
    print(format_req(fields), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
