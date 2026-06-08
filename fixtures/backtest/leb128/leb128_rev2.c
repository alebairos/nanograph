/* G31 demo specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * A small unsigned LEB128 codec with two modes.
 *   enc <value>   prints the LEB128 bytes packed as 0x01 ++ bytes, decimal.
 *   dec <packed>  prints the decoded value, or REJECT for a byte sequence the
 *                 decoder does not accept.
 * Same 0x01 sentinel packing as the UTF-8 specimen, capped to 4 varint bytes so
 * packed fits in 40 bits. The honest decoder rejects non-minimal encodings.
 * NONMINIMAL_OK drops the minimality check, the classic varint hole where 80 00
 * decodes to 0. round_trip catches it, encode(decode(80 00)) = 00, not 80 00. */

#define REJECT 4294967295UL

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

static unsigned long leb128_encode(unsigned long v) {
  unsigned long r = 1UL;
  for (;;) {
    unsigned long byte = v & 0x7FUL;
    v >>= 7;
    if (v)
      byte |= 0x80UL;
    r = (r << 8) | byte;
    if (!v)
      break;
  }
  return r;
}

static unsigned long leb128_decode(unsigned long packed) {
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

  unsigned long value = 0UL;
  int shift = 0;
  for (int k = 0; k < n; k++) {
    value |= (b[k] & 0x7FUL) << shift;
    shift += 7;
    int cont = (b[k] & 0x80UL) != 0UL;
    if (k == n - 1) {
      if (cont)
        return REJECT;
    } else {
      if (!cont)
        return REJECT;
    }
  }
  return value;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  unsigned long x = parse_u(operand);
  if (mode[0] == 'e')
    print_u(leb128_encode(x));
  else if (mode[0] == 'd')
    print_u(leb128_decode(x));
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
