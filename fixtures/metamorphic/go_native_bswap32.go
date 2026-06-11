// G76 native Go lang-pack specimen. Static CGO_ENABLED=0 x86_64 Linux ELF
// (Go runtime, no libc). Reads argv[1] as an unsigned 32-bit value; prints
// bswap32(x) in decimal. Same driver ABI as fixtures/metamorphic/bswap32.c so
// the unchanged verifier checks it under bswap32.req (relation=involution).
package main

import "os"

func main() {
	if len(os.Args) < 2 {
		os.Exit(2)
	}
	var n uint64
	for _, c := range []byte(os.Args[1]) {
		if c < '0' || c > '9' {
			break
		}
		n = n*10 + uint64(c-'0')
	}
	x := uint32(n)
	y := mapU32(x)
	buf := make([]byte, 0, 16)
	if y == 0 {
		buf = append(buf, '0')
	} else {
		var tmp [16]byte
		j := 0
		for y > 0 {
			tmp[j] = byte('0' + y%10)
			y /= 10
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
