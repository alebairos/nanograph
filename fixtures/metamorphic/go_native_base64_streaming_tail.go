//go:build !notail

package main

func tryTailDecode(d *streamDec) int {
	if d.nbuf <= 0 || d.readEOF == 0 {
		return 0
	}
	var q [4]byte
	for i := 0; i < d.nbuf; i++ {
		q[i] = decMap[d.buf[i]]
	}
	nw := decodeQuantum(q[:], d.nbuf, d.outbuf[:])
	d.nbuf = 0
	d.end = 1
	d.outLen = nw
	return nw
}
