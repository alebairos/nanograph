//go:build evil

package main

func mapU32(x uint32) uint32 {
	return x<<8 | x>>24
}
