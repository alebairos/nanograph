#include <stddef.h>

/* Hex codec maintained by the persona. Hosted C, not freestanding. */

static int nibble(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

size_t hex_encode(const unsigned char *in, size_t in_len, char *out) {
  static const char digits[] = "0123456789abcdef";
  size_t i;
  for (i = 0; i < in_len; i++) {
    out[2 * i] = digits[in[i] >> 4];
    out[2 * i + 1] = digits[in[i] & 0x0f];
  }
  return 2 * in_len;
}

/* Returns decoded length, or 0 on invalid input (odd length or bad digit). */
size_t hex_decode(const char *in, size_t in_len, unsigned char *out) {
  size_t i;
  if (in_len % 2 != 0) return 0;
  for (i = 0; i < in_len; i += 2) {
    int hi = nibble(in[i]);
    int lo = nibble(in[i + 1]);
    if (hi < 0 || lo < 0) return 0;
    out[i / 2] = (unsigned char)((hi << 4) | lo);
  }
  return in_len / 2;
}
