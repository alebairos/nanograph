/* Spike-only cosmopolitan port of fixtures/metamorphic/utf8.c logic for G54 H2.
 * Same packing and OVERLONG_OK semantics; libc I/O instead of raw syscalls. */

#include <stdio.h>
#include <stdlib.h>

#define REJECT 1114112UL

static unsigned long parse_u(const char *s) {
  unsigned long n = 0;
  while (*s >= '0' && *s <= '9') {
    n = n * 10UL + (unsigned long)(*s - '0');
    s++;
  }
  return n;
}

static void print_u(unsigned long n) {
  printf("%lu\n", n);
}

static unsigned long utf8_encode(unsigned long cp) {
  unsigned long r = 1UL;
  if (cp < 0x80UL) {
    r = (r << 8) | cp;
  } else if (cp < 0x800UL) {
    r = (r << 8) | (0xC0UL | (cp >> 6));
    r = (r << 8) | (0x80UL | (cp & 0x3FUL));
  } else if (cp < 0x10000UL) {
    r = (r << 8) | (0xE0UL | (cp >> 12));
    r = (r << 8) | (0x80UL | ((cp >> 6) & 0x3FUL));
    r = (r << 8) | (0x80UL | (cp & 0x3FUL));
  } else {
    r = (r << 8) | (0xF0UL | (cp >> 18));
    r = (r << 8) | (0x80UL | ((cp >> 12) & 0x3FUL));
    r = (r << 8) | (0x80UL | ((cp >> 6) & 0x3FUL));
    r = (r << 8) | (0x80UL | (cp & 0x3FUL));
  }
  return r;
}

static unsigned long utf8_decode(unsigned long packed) {
  int n = 0;
  for (int k = 1; k <= 4; k++) {
    if ((packed >> (8 * k)) == 1UL) {
      n = k;
      break;
    }
  }
  if (n == 0)
    return REJECT;

  unsigned long b[4];
  for (int k = 0; k < n; k++)
    b[k] = (packed >> (8 * (n - 1 - k))) & 0xFFUL;

  unsigned long cp;
  if (n == 1) {
    if (b[0] >= 0x80UL)
      return REJECT;
    cp = b[0];
  } else if (n == 2) {
    if ((b[0] & 0xE0UL) != 0xC0UL || (b[1] & 0xC0UL) != 0x80UL)
      return REJECT;
    cp = ((b[0] & 0x1FUL) << 6) | (b[1] & 0x3FUL);
#if !defined(OVERLONG_OK)
    if (cp < 0x80UL)
      return REJECT;
#endif
  } else if (n == 3) {
    if ((b[0] & 0xF0UL) != 0xE0UL || (b[1] & 0xC0UL) != 0x80UL ||
        (b[2] & 0xC0UL) != 0x80UL)
      return REJECT;
    cp = ((b[0] & 0x0FUL) << 12) | ((b[1] & 0x3FUL) << 6) | (b[2] & 0x3FUL);
#if !defined(OVERLONG_OK)
    if (cp < 0x800UL)
      return REJECT;
#endif
    if (cp >= 0xD800UL && cp <= 0xDFFFUL)
      return REJECT;
  } else {
    if ((b[0] & 0xF8UL) != 0xF0UL || (b[1] & 0xC0UL) != 0x80UL ||
        (b[2] & 0xC0UL) != 0x80UL || (b[3] & 0xC0UL) != 0x80UL)
      return REJECT;
    cp = ((b[0] & 0x07UL) << 18) | ((b[1] & 0x3FUL) << 12) |
         ((b[2] & 0x3FUL) << 6) | (b[3] & 0x3FUL);
#if !defined(OVERLONG_OK)
    if (cp < 0x10000UL)
      return REJECT;
#endif
    if (cp > 0x10FFFFUL)
      return REJECT;
  }
  return cp;
}

int main(int argc, char **argv) {
  if (argc < 3)
    return 1;
  unsigned long x = parse_u(argv[2]);
  if (argv[1][0] == 'e')
    print_u(utf8_encode(x));
  else if (argv[1][0] == 'd')
    print_u(utf8_decode(x));
  else
    return 1;
  return 0;
}
