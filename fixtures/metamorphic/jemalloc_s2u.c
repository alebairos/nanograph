/* G49 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of jemalloc/jemalloc sz_s2u_compute_using_delta
 * (include/jemalloc/internal/sz.h). Parent 136d342aa094 omits overflow guards;
 * fix 6b245225459f adds checks for size > SC_LARGE_MAXCLASS and for
 * size > SIZE_T_MAX - delta_mask. BSD-2-Clause.
 *
 *   s2u <size>   print the rounded usable size for a request (decimal u64).
 *
 * size_monotone: for ascending request sizes x < y, usable(x) <= usable(y).
 * The buggy rev wraps near SIZE_T_MAX and inverts against the top valid class. */

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

#define LG_QUANTUM 4
#define SC_LG_NGROUP 2
#define SC_LARGE_MAXCLASS 0x7000000000000000UL

static unsigned lg_floor(unsigned long v) {
  if (v == 0)
    return 0;
  unsigned r = 0;
  while (v > 1) {
    v >>= 1;
    r++;
  }
  return r;
}

static unsigned long sz_s2u_compute_using_delta(unsigned long size) {
#if !defined(S2U_OVERFLOW_OK)
  if (size > SC_LARGE_MAXCLASS)
    return 0;
#endif
  unsigned long x = lg_floor((size << 1) - 1);
  unsigned long lg_delta = (x < SC_LG_NGROUP + LG_QUANTUM + 1)
      ? LG_QUANTUM
      : x - SC_LG_NGROUP - 1;
  unsigned long delta = 1UL << lg_delta;
  unsigned long delta_mask = delta - 1;
#if !defined(S2U_OVERFLOW_OK)
  if (size > (unsigned long)-1 - delta_mask)
    return 0;
#endif
  return (size + delta_mask) & ~delta_mask;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *arg1) {
  if (argc < 3)
    sys_exit(1);
  if (mode[0] != 's' || mode[1] != '2' || mode[2] != 'u' || mode[3] != '\0')
    sys_exit(1);
  print_u(sz_s2u_compute_using_delta(parse_u(arg1)));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
