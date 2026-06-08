/* G27 demo specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * A small UTF-8 codec with two modes.
 *   enc <codepoint>  prints the UTF-8 bytes packed as 0x01 ++ bytes, decimal.
 *   dec <packed>     prints the decoded codepoint, or REJECT for a byte
 *                    sequence the decoder does not accept.
 * The 0x01 sentinel makes the byte length unambiguous after packing, so a
 * variable-length encoding still fits one integer and the two-pass metamorphic
 * runner. Max 4 UTF-8 bytes plus the sentinel fit in 40 bits.
 *
 * The honest decoder rejects overlong forms, surrogates, and out-of-range
 * codepoints. OVERLONG_OK drops only the overlong lower-bound checks: the
 * classic security hole where C0 80 decodes to U+0000. round_trip catches it,
 * encode(decode(C0 80)) = 00, not C0 80. */

#define REJECT 1114112UL

static long sys_write(long fd, const void *buf, long n) {
  long ret;
  __asm__ volatile("syscall"
                   : "=a"(ret)
                   : "a"(1L), "D"(fd), "S"(buf), "d"(n)
                   : "rcx", "r11", "memory");
  return ret;
}

static void sys_exit(long code) __attribute__((noreturn));
static void sys_exit(long code) {
  __asm__ volatile("syscall" : : "a"(60L), "D"(code) : "rcx", "r11", "memory");
  __builtin_unreachable();
}

static unsigned long parse_u(const char *s) {
  unsigned long n = 0;
  while (*s >= '0' && *s <= '9') {
    n = n * 10UL + (unsigned long)(*s - '0');
    s++;
  }
  return n;
}

static void print_u(unsigned long n) {
  char buf[32];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[32];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10UL));
      n /= 10UL;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
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
  } else if (n == 3) {
    if ((b[0] & 0xF0UL) != 0xE0UL || (b[1] & 0xC0UL) != 0x80UL ||
        (b[2] & 0xC0UL) != 0x80UL)
      return REJECT;
    cp = ((b[0] & 0x0FUL) << 12) | ((b[1] & 0x3FUL) << 6) | (b[2] & 0x3FUL);
    if (cp >= 0xD800UL && cp <= 0xDFFFUL)
      return REJECT;
  } else {
    if ((b[0] & 0xF8UL) != 0xF0UL || (b[1] & 0xC0UL) != 0x80UL ||
        (b[2] & 0xC0UL) != 0x80UL || (b[3] & 0xC0UL) != 0x80UL)
      return REJECT;
    cp = ((b[0] & 0x07UL) << 18) | ((b[1] & 0x3FUL) << 12) |
         ((b[2] & 0x3FUL) << 6) | (b[3] & 0x3FUL);
    if (cp > 0x10FFFFUL)
      return REJECT;
  }
  return cp;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  unsigned long x = parse_u(operand);
  if (mode[0] == 'e')
    print_u(utf8_encode(x));
  else if (mode[0] == 'd')
    print_u(utf8_decode(x));
  else
    sys_exit(1);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
