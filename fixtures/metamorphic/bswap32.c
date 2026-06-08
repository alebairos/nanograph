/* G24 metamorphic specimen. Freestanding x86_64 Linux ELF, no libc.
 * Reads argv[1] as an unsigned 32-bit value; prints bswap32(x) in decimal.
 * The relation f(f(x))==x (involution) is the oracle; no expected value is
 * computed by the verifier. Linux x86_64 ABI: argc at [rsp], argv[i] at
 * rsp+8+i*8. Minted once in a pinned container; CI runs the committed image. */

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

#if defined(EVIL_BSWAP)
/* Rotate-by-8 misread for a byte swap. f(f(x)) is rotate-by-16, not the
 * identity, so the involution relation rejects it on any value whose low and
 * high halfwords differ. */
static unsigned long bswap32(unsigned long x) {
  unsigned long v = x & 0xFFFFFFFFUL;
  return ((v << 8) | (v >> 24)) & 0xFFFFFFFFUL;
}
#elif defined(IMPOSTER_BSWAP)
/* Swaps only the outer byte pair; leaves the inner pair. This IS an involution
 * (applying it twice restores the input) but it is NOT a byte swap. The
 * involution relation accepts it: the documented ceiling. Only a value oracle
 * separates it from the real bswap32. */
static unsigned long bswap32(unsigned long x) {
  unsigned long v = x & 0xFFFFFFFFUL;
  return ((v & 0x000000FFUL) << 24) | (v & 0x0000FF00UL) | (v & 0x00FF0000UL) |
         ((v & 0xFF000000UL) >> 24);
}
#else
static unsigned long bswap32(unsigned long x) {
  unsigned long v = x & 0xFFFFFFFFUL;
  return ((v & 0x000000FFUL) << 24) | ((v & 0x0000FF00UL) << 8) |
         ((v & 0x00FF0000UL) >> 8) | ((v & 0xFF000000UL) >> 24);
}
#endif

__attribute__((noreturn))
void real_start(long argc, const char *arg1) {
  if (argc < 2)
    sys_exit(1);
  print_u(bswap32(parse_u(arg1)));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "call real_start\n");
}
