/* G42 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of golang/go encoding/hex Decode (hex.go).
 * Parent 02d8ebda returns 0 bytes written when dst is too small; fix
 * f02cdba1 reports the partial decode already written to dst on overflow.
 *
 *   dec <hexstring>   hex-decode the operand into an 8-byte dst buffer left
 *                     to right; print decoded bytes as lowercase hex, or REJECT.
 *
 * value_oracle: dec(s) must match expected for accepted inputs; the buggy rev
 * reports nothing written on dst overflow.
 *
 * Compile-time flag ZERO_ON_OVERFLOW selects the parent overflow behavior. */

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

static int hexval(unsigned char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

static int hex_decode_dst8(const char *s, unsigned char *out, int *overflow) {
  int written = 0;
  int i = 0;
  *overflow = 0;
  while (s[i] && s[i + 1]) {
    int hi = hexval((unsigned char)s[i]);
    int lo = hexval((unsigned char)s[i + 1]);
    if (hi < 0 || lo < 0) return -1;
    if (written < 8) {
      out[written++] = (unsigned char)((hi << 4) | lo);
    } else {
      *overflow = 1;
      return 8;
    }
    i += 2;
  }
  if (s[i]) return -1;
  return written;
}

static void print_str(const char *s) {
  int n = 0;
  while (s[n]) n++;
  sys_write(1, s, n);
}

static void print_hex(const unsigned char *b, int n) {
  static const char hexd[] = "0123456789abcdef";
  char out[32];
  int i = 0;
  for (int k = 0; k < n; k++) {
    out[i++] = hexd[b[k] >> 4];
    out[i++] = hexd[b[k] & 15];
  }
  out[i++] = '\n';
  sys_write(1, out, i);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3 || mode[0] != 'd')
    sys_exit(1);
  unsigned char dst[8];
  int overflow = 0;
  int n = hex_decode_dst8(operand, dst, &overflow);
  if (n < 0) {
    print_str("REJECT\n");
    sys_exit(0);
  }
  if (overflow) {
#if defined(ZERO_ON_OVERFLOW)
    print_str("REJECT\n");
#else
    print_hex(dst, 8);
#endif
    sys_exit(0);
  }
  print_hex(dst, n);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
