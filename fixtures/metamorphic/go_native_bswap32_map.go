//go:build !evil

package main

func mapU32(x uint32) uint32 {
	return x>>24 | x>>8&0xff00 | x<<8&0xff0000 | x<<24
}
