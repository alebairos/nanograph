/* G41 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of jart/cosmopolitan ParseIp (net/http/parseip.c).
 * Parent 539bddc accumulates octet digits without overflow guards; fix c995838
 * adds __builtin_mul/add_overflow checks and rejects b > 255 when dotted.
 *
 *   dec <ipv4>   print host-order u32 decimal, or REJECT on failure.
 *
 * value_oracle: parse(s) must match expected for accepted addresses. Buggy rev
 * accepts 255.255.255.256 with a wrapped/wrong value instead of REJECT. */

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

static int is_digit(unsigned char c) { return c >= '0' && c <= '9'; }


#if defined(IP_OVERFLOW_OK)

static int add_digit(unsigned *b, unsigned char c, int dotted) {
  (void)dotted;
  *b = *b * 10U + (unsigned)(c - '0');
  return 0;
}

#endif

static long parse_ip(const char *s) {
  unsigned x = 0;
  unsigned b = 0;
  int dotted = 0;
  int n = 0;
  while (s[n])
    n++;
  if (!n)
    return -1;
  for (int i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if (is_digit(c)) {
      if (add_digit(&b, c, dotted))
        return -1;
    } else if (c == '.') {
      if (b > 255U)
        return -1;
      dotted = 1;
      x = (x << 8) | b;
      b = 0;
    } else {
      return -1;
    }
  }
  x = (x << 8) | b;
  return (long)x;
}

static void print_u(unsigned long n) {
  char buf[16];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    while (n) {
      buf[i++] = (char)('0' + (n % 10UL));
      n /= 10UL;
    }
    for (int l = 0, r = i - 1; l < r; l++, r--) {
      char t = buf[l];
      buf[l] = buf[r];
      buf[r] = t;
    }
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static void print_str(const char *s) {
  int n = 0;
  while (s[n])
    n++;
  sys_write(1, s, n);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3 || mode[0] != 'd')
    sys_exit(1);
  long v = parse_ip(operand);
  if (v < 0)
    print_str("REJECT\n");
  else
    print_u((unsigned long)v);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
