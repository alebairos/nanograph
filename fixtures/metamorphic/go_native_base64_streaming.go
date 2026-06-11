// G58 native Go lang-pack specimen. Static CGO_ENABLED=0 x86_64 Linux ELF.
// Faithful port of fixtures/metamorphic/go_base64_streaming.c (golang/go
// encoding/base64 RawURLEncoding streaming decode). Driver ABI:
//   flow <len> <seed|token>
// rev2: --tags notail (parent drops final nbuf<4 fragment).
package main

import (
	"os"
	"strconv"
)

const partialN = 4

func probeB64(seed uint64) string {
	switch seed {
	case 5:
		return "AAAAAA"
	case 7:
		return "BBBBBB"
	case 42:
		return "YWJjZA"
	case 13:
		return "AAABBB"
	default:
		return ""
	}
}

func initMaps() [256]byte {
	const enc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
	var dec [256]byte
	for i := range dec {
		dec[i] = 0xff
	}
	for i := 0; i < 64; i++ {
		dec[enc[i]] = byte(i)
	}
	return dec
}

var decMap = initMaps()

func decodeQuantum(dbuf []byte, dlen int, dst []byte) int {
	val := (uint32(dbuf[0]) << 18) | (uint32(dbuf[1]) << 12) | (uint32(dbuf[2]) << 6) | uint32(dbuf[3])
	n := 0
	if dlen >= 2 {
		dst[n] = byte(val >> 16)
		n++
	}
	if dlen >= 3 {
		dst[n] = byte(val >> 8)
		n++
	}
	if dlen >= 4 {
		dst[n] = byte(val)
		n++
	}
	return n
}

func decodeOneShot(src string, dst []byte) (int, bool) {
	si := 0
	n := 0
	for si < len(src) {
		var dbuf [4]byte
		dlen := 0
		for j := 0; j < 4; j++ {
			if si >= len(src) {
				if j < 2 {
					return 0, false
				}
				dlen = j
				break
			}
			c := src[si]
			si++
			if decMap[c] == 0xff {
				return 0, false
			}
			dbuf[j] = decMap[c]
			dlen = j + 1
		}
		nw := decodeQuantum(dbuf[:], dlen, dst[n:])
		if n+nw > len(dst) {
			return 0, false
		}
		n += nw
	}
	return n, true
}

type streamDec struct {
	err       int
	readEOF   int
	end       int
	nbuf      int
	buf       [256]byte
	outLen    int
	outbuf    [192]byte
	pos       int
	input     string
	inputLen  int
	origSeed  uint64
	produced  int
}

func decRead(d *streamDec, p []byte) int {
	if d.outLen > 0 {
		n := d.outLen
		if n > len(p) {
			n = len(p)
		}
		copy(p, d.outbuf[:n])
		copy(d.outbuf[:], d.outbuf[n:d.outLen])
		d.outLen -= n
		return n
	}
	if d.err != 0 {
		return 0
	}

	for d.nbuf < 4 && d.readEOF == 0 && d.pos < d.inputLen {
		d.buf[d.nbuf] = d.input[d.pos]
		d.nbuf++
		d.pos++
	}
	if d.pos >= d.inputLen {
		d.readEOF = 1
	}

	if d.nbuf < 4 {
		if n := tryTailDecode(d); n > 0 {
			take := n
			if take > len(p) {
				take = len(p)
			}
			copy(p, d.outbuf[:take])
			copy(d.outbuf[:], d.outbuf[take:d.outLen])
			d.outLen -= take
			return take
		}
		if d.readEOF != 0 && d.nbuf > 0 {
			d.err = 1
			return 0
		}
		return 0
	}

	var q [4]byte
	for i := 0; i < 4; i++ {
		q[i] = decMap[d.buf[i]]
	}
	var out [192]byte
	dn := decodeQuantum(q[:], 4, out[:])
	d.nbuf = 0
	n := dn
	if n > len(p) {
		n = len(p)
	}
	copy(p, out[:n])
	if dn > n {
		d.outLen = dn - n
		copy(d.outbuf[:], out[n:dn])
	}
	return n
}

func streamLen(d *streamDec) uint64 {
	var tmp [64]byte
	var n uint64
	for {
		r := decRead(d, tmp[:])
		if r <= 0 {
			break
		}
		n += uint64(r)
	}
	return n
}

func putU20(out []byte, pos *int, cap int, v uint64) {
	for d := 19; d >= 0; d-- {
		div := uint64(1)
		for e := 0; e < d; e++ {
			div *= 10
		}
		if *pos+1 >= cap {
			return
		}
		out[*pos] = byte('0' + (v/div)%10)
		*pos++
	}
}

func packToken(d *streamDec) {
	var out [1200]byte
	pos := 0
	out[pos] = '2'
	pos++
	putU20(out[:], &pos, len(out), d.origSeed)
	putU20(out[:], &pos, len(out), uint64(d.pos))
	putU20(out[:], &pos, len(out), uint64(d.nbuf))
	putU20(out[:], &pos, len(out), uint64(d.outLen))
	putU20(out[:], &pos, len(out), uint64(d.end))
	putU20(out[:], &pos, len(out), uint64(d.err))
	putU20(out[:], &pos, len(out), uint64(d.readEOF))
	putU20(out[:], &pos, len(out), uint64(d.produced))
	if pos+3 >= len(out) {
		return
	}
	out[pos] = byte('0' + (d.nbuf/100)%10)
	pos++
	out[pos] = byte('0' + (d.nbuf/10)%10)
	pos++
	out[pos] = byte('0' + d.nbuf%10)
	pos++
	for i := 0; i < d.nbuf; i++ {
		if pos+3 >= len(out) {
			return
		}
		out[pos] = byte('0' + (int(d.buf[i])/100)%10)
		pos++
		out[pos] = byte('0' + (int(d.buf[i])/10)%10)
		pos++
		out[pos] = byte('0' + int(d.buf[i])%10)
		pos++
	}
	if pos+3 >= len(out) {
		return
	}
	out[pos] = byte('0' + (d.outLen/100)%10)
	pos++
	out[pos] = byte('0' + (d.outLen/10)%10)
	pos++
	out[pos] = byte('0' + d.outLen%10)
	pos++
	for i := 0; i < d.outLen; i++ {
		if pos+3 >= len(out) {
			return
		}
		out[pos] = byte('0' + (int(d.outbuf[i])/100)%10)
		pos++
		out[pos] = byte('0' + (int(d.outbuf[i])/10)%10)
		pos++
		out[pos] = byte('0' + int(d.outbuf[i])%10)
		pos++
	}
	if pos+1 >= len(out) {
		return
	}
	out[pos] = '\n'
	pos++
	os.Stdout.Write(out[:pos])
}

func unpackToken(s string, d *streamDec) bool {
	if len(s) == 0 || s[0] != '2' {
		return false
	}
	s = s[1:]
	var fields [8]uint64
	for f := 0; f < 8; f++ {
		var v uint64
		for j := 0; j < 20; j++ {
			if len(s) == 0 || s[0] < '0' || s[0] > '9' {
				return false
			}
			v = v*10 + uint64(s[0]-'0')
			s = s[1:]
		}
		fields[f] = v
	}
	d.origSeed = fields[0]
	d.pos = int(fields[1])
	d.nbuf = int(fields[2])
	d.outLen = int(fields[3])
	d.end = int(fields[4])
	d.err = int(fields[5])
	d.readEOF = int(fields[6])
	d.produced = int(fields[7])
	bl := 0
	for j := 0; j < 3; j++ {
		if len(s) == 0 || s[0] < '0' || s[0] > '9' {
			return false
		}
		bl = bl*10 + int(s[0]-'0')
		s = s[1:]
	}
	if bl != d.nbuf {
		return false
	}
	for i := 0; i < d.nbuf; i++ {
		b := 0
		for j := 0; j < 3; j++ {
			if len(s) == 0 || s[0] < '0' || s[0] > '9' {
				return false
			}
			b = b*10 + int(s[0]-'0')
			s = s[1:]
		}
		d.buf[i] = byte(b)
	}
	ol := 0
	for j := 0; j < 3; j++ {
		if len(s) == 0 || s[0] < '0' || s[0] > '9' {
			return false
		}
		ol = ol*10 + int(s[0]-'0')
		s = s[1:]
	}
	if ol != d.outLen {
		return false
	}
	for i := 0; i < d.outLen; i++ {
		b := 0
		for j := 0; j < 3; j++ {
			if len(s) == 0 || s[0] < '0' || s[0] > '9' {
				return false
			}
			b = b*10 + int(s[0]-'0')
			s = s[1:]
		}
		d.outbuf[i] = byte(b)
	}
	return true
}

func makeDec(seed uint64) streamDec {
	in := probeB64(seed)
	if in == "" {
		os.Exit(1)
	}
	return streamDec{
		origSeed: seed,
		input:    in,
		inputLen: len(in),
	}
}

func flowPartial(partialIn uint64, seed uint64) {
	d := makeDec(seed)
	limit := int(partialIn)
	if limit > d.inputLen {
		limit = d.inputLen
	}
	d.inputLen = limit
	var tmp [64]byte
	for d.err == 0 && d.end == 0 {
		n := decRead(&d, tmp[:])
		if n <= 0 && d.readEOF != 0 {
			break
		}
		if n <= 0 && d.nbuf >= 4 {
			continue
		}
		if n <= 0 {
			break
		}
		d.produced += n
	}
	in := probeB64(seed)
	d.input = in
	d.inputLen = len(in)
	packToken(&d)
}

func flowOneShot(total uint64, seed uint64) uint64 {
	in := probeB64(seed)
	if in == "" {
		os.Exit(1)
	}
	if uint64(len(in)) != total {
		os.Exit(1)
	}
	var out [64]byte
	n, ok := decodeOneShot(in, out[:])
	if !ok {
		os.Exit(1)
	}
	return uint64(n)
}

func flowContinue(token string) {
	d := streamDec{}
	if !unpackToken(token, &d) {
		os.Exit(1)
	}
	in := probeB64(d.origSeed)
	if in == "" {
		os.Exit(1)
	}
	d.input = in
	d.inputLen = len(in)
	if d.pos >= d.inputLen {
		d.readEOF = 1
	} else {
		d.readEOF = 0
	}
	d.err = 0
	printU64(uint64(d.produced) + streamLen(&d))
}

func printU64(n uint64) {
	buf := make([]byte, 0, 32)
	if n == 0 {
		buf = append(buf, '0')
	} else {
		var tmp [32]byte
		j := 0
		for n > 0 {
			tmp[j] = byte('0' + n%10)
			n /= 10
			j++
		}
		for j > 0 {
			j--
			buf = append(buf, tmp[j])
		}
	}
	buf = append(buf, '\n')
	os.Stdout.Write(buf)
}

func main() {
	if len(os.Args) < 4 {
		os.Exit(1)
	}
	if os.Args[1] != "flow" {
		os.Exit(1)
	}
	length, err := strconv.ParseUint(os.Args[2], 10, 64)
	if err != nil {
		os.Exit(1)
	}
	arg := os.Args[3]
	if len(arg) > 0 && arg[0] == '2' {
		flowContinue(arg)
		return
	}
	seed, err := strconv.ParseUint(arg, 10, 64)
	if err != nil {
		os.Exit(1)
	}
	if length == partialN {
		flowPartial(length, seed)
		return
	}
	printU64(flowOneShot(length, seed))
}
