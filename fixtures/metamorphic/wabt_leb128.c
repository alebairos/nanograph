/* G34 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of wabt's ReadU64Leb128 decode and its real too-big
 * mask bug (src/leb128.cc). wabt #2256 (commit f1f3d6d, parent 89582f5) changed
 * the 10th-byte overflow check from p[9] & 0xf0 to p[9] & 0xfe; 0xf0 was copied
 * from the u32 path and missed bits 1..3, so a 10-byte LEB128 encoding a value
 * above u64 max was silently accepted and truncated. This file keeps the base
 * 0xf0 check and adds the 0x0e bits the fix restored (0xf0 | 0x0e == 0xfe); the
 * WABT_BUG revision drops the 0x0e block.
 *
 * The decode arithmetic and the masks are wabt's. This is not a verbatim build
 * of wabt's C++ (which needs its own types and is not freestanding). _start, the
 * hex parse, and print are our trusted driver.
 *
 *   dec <hexbytes>   decode a LEB128 byte string; print u64 decimal or REJECT.
 *   enc <decimal>    canonical-encode a u64; print LEB128 bytes as lowercase hex.
 * round_trip: enc(dec(b)) == b for accepted b. The buggy mask accepts a too-big
 * 10-byte input, decodes to a truncated value, and enc of that value is shorter,
 * so round_trip rejects it with the offending bytes. */

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

static int hex_nibble(char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  if (c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  if (c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  return -1;
}

static int parse_hex(const char *s, unsigned char *out, int cap) {
  int n = 0;
  while (s[0] && s[1]) {
    int hi = hex_nibble(s[0]);
    int lo = hex_nibble(s[1]);
    if (hi < 0 || lo < 0 || n >= cap)
      return -1;
    out[n++] = (unsigned char)((hi << 4) | lo);
    s += 2;
  }
  if (s[0])
    return -1;
  return n;
}

static unsigned long parse_u(const char *s) {
  unsigned long n = 0;
  while (*s >= '0' && *s <= '9') {
    n = n * 10UL + (unsigned long)(*s - '0');
    s++;
  }
  return n;
}

static void print_str(const char *s) {
  long n = 0;
  while (s[n])
    n++;
  sys_write(1, s, n);
}

static void print_u(unsigned long n) {
  char buf[24];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[24];
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

static void print_hex_bytes(const unsigned char *b, int n) {
  static const char d[] = "0123456789abcdef";
  char buf[64];
  int i = 0;
  for (int k = 0; k < n; k++) {
    buf[i++] = d[(b[k] >> 4) & 0xf];
    buf[i++] = d[b[k] & 0xf];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

static int read_u64_leb128(const unsigned char *p, int n, unsigned long *out) {
  unsigned long result = 0;
  for (int i = 0; i < 10; i++) {
    if (i >= n)
      return 0;
    result |= ((unsigned long)(p[i] & 0x7f)) << (i * 7);
    if ((p[i] & 0x80) == 0) {
      if (i == 9) {
        unsigned mask = 0xf0;
#if !defined(WABT_BUG)
        mask |= 0x0e;
#endif
        if (p[i] & mask)
          return 0;
      }
      *out = result;
      return i + 1;
    }
  }
  return 0;
}

static int enc_canonical(unsigned long v, unsigned char *out) {
  int n = 0;
  do {
    unsigned char byte = (unsigned char)(v & 0x7fUL);
    v >>= 7;
    if (v)
      byte |= 0x80;
    out[n++] = byte;
  } while (v);
  return n;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  if (mode[0] == 'd') {
    unsigned char b[16];
    int n = parse_hex(operand, b, 16);
    unsigned long value;
    if (n <= 0 || read_u64_leb128(b, n, &value) == 0)
      print_str("REJECT\n");
    else
      print_u(value);
  } else if (mode[0] == 'e') {
    unsigned char out[16];
    int n = enc_canonical(parse_u(operand), out);
    print_hex_bytes(out, n);
  } else {
    sys_exit(1);
  }
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
