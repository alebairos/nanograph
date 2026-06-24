# Vendored verbatim from 1200wd/bitcoinlib bitcoinlib/encoding.py
# Upstream: https://github.com/1200wd/bitcoinlib
# Commit: bec99a2b05a7dc86b6029fafe2b464fa8ccc0ac9 (2026-06-05)
# License: MIT (see upstream repository)
# Extract: EncodingError, varbyteint_to_int, int_to_varbyteint (CompactSize)

import numbers


class EncodingError(Exception):
    pass


def varbyteint_to_int(byteint):
    if not isinstance(byteint, (bytes, list)):
        raise EncodingError("Byteint must be a list or defined as bytes")
    if byteint == b'':
        return 0, 0
    ni = byteint[0]
    if ni < 253:
        return ni, 1
    if ni == 253:
        size = 2
    elif ni == 254:
        size = 4
    else:
        size = 8
    return int.from_bytes(byteint[1:1+size][::-1], 'big'), size + 1


def int_to_varbyteint(inp):
    if not isinstance(inp, numbers.Number):
        raise EncodingError("Input must be a number type")
    if inp < 0xfd:
        return inp.to_bytes(1, 'little')
    elif inp < 0xffff:
        return b'\xfd' + inp.to_bytes(2, 'little')
    elif inp < 0xffffffff:
        return b'\xfe' + inp.to_bytes(4, 'little')
    else:
        return b'\xff' + inp.to_bytes(8, 'little')
