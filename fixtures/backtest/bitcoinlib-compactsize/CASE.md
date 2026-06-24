# 1200wd/bitcoinlib CompactSize native hunt (G86)

`1200wd/bitcoinlib`, https://github.com/1200wd/bitcoinlib , MIT.

`fixtures/native/bitcoinlib_compactsize` runs the upstream `int_to_varbyteint` and `varbyteint_to_int` from `bitcoinlib/encoding.py` at commit `bec99a2b05a7dc86b6029fafe2b464fa8ccc0ac9` (2026-06-05). When `pip install bitcoinlib` is unavailable (e.g. Python 3.14 without `gmp` for `fastecdsa`), the same functions are vendored verbatim in `fixtures/native/bitcoinlib-vendor/compactsize.py`. The CLI wrapper is ours; the codec logic is upstream's.

This is a **native** hunt (G85 vehicle), not a freestanding `.ngb` transcription. Real upstream code ran; a reject is not a transcription artifact.

## The defect

Bitcoin consensus CompactSize must use the minimal byte encoding. Core rejects non-minimal forms (see bitcoin/bitcoin#8721).

`int_to_varbyteint` uses strict `<` at the u16 and u32 boundaries:

```python
elif inp < 0xffff:       # should be <= 0xffff for 65535
    return b'\xfd' + ...
elif inp < 0xffffffff:   # same class at u32 max
    return b'\xfe' + ...
```

So `65535` encodes as `feffff0000` (4-byte prefix) instead of canonical `fdffff` (2-byte prefix).

`varbyteint_to_int` decodes non-minimal encodings without rejecting them (no minimality check).

## Pre-registered property

`round_trip` via `fixtures/native/bitcoinlib_compactsize.req` with `canonical=enforced` and `probes_cmd=scripts/agent-eval/gen-compactsize.sh`.

## Catch

| Field | Value |
| --- | --- | --- |
| Vehicle | `native-hunt.sh` |
| Verdict | `reject` |
| Witness bytes | `fdffff` |
| Decode | `65535` |
| Reencode | `feffff0000` |

The probe `fdffff` is a **canonical** on-wire encoding. Decode succeeds; re-encode violates minimality. This is an encoder boundary at the u16 limit, not merely accepting a non-minimal input.

Additional failure class (not first witness): non-minimal inputs such as `fd0000` decode and re-encode to `00` because the decoder does not enforce minimality.

## Contrast

| Target | Verdict | Detail |
| --- | --- | --- |
| `rust-bitcoin` `VarInt` 0.32 | accept | honest null at HEAD |
| `1200wd/bitcoinlib` CompactSize | reject | witness above |

## Rerun

```bash
./scripts/agent-eval/native-hunt.sh fixtures/native/bitcoinlib_compactsize fixtures/native/bitcoinlib_compactsize.req
./scripts/check-bitcoinlib-compactsize-hunt.sh
```

## Maintainer report shape

Subject: CompactSize non-minimal encoding at u16/u32 boundaries in `bitcoinlib.encoding.int_to_varbyteint`

Steps:

1. `int_to_varbyteint(65535)` returns `feffff0000` instead of canonical `fdffff`.
2. `varbyteint_to_int` accepts non-minimal wire forms (e.g. `fd0000` for value 0).
3. Bitcoin Core rejects non-minimal CompactSize on the P2P wire.

Found via metamorphic `round_trip` with blind-generated probes; witness `fdffff` on upstream code without transcription.
