// G77 native Go lang-pack evil specimen (rotl8, non-involution). Same ABI as
// go_native_bswap32.go; paired for rust-bswap32-native / go-bswap32-native backtests.
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
	y := x<<8 | x>>24
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
