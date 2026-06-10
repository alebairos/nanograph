/* G42 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of jart/cosmopolitan ljson JSON-string decoding
 * (tool/net/ljson.c). Parent ccd057a copies string-body bytes verbatim with no
 * UTF-8 validation; fix baf51a4 ("Add utf-8 validation to ljson") adds the
 * kJsonStr classifier and rejects overlong, surrogate, and malformed sequences.
 *
 *   dec <hex>   hex-decode the operand to raw string-body bytes, run the ljson
 *               decoder, print the decoded bytes as lowercase hex, or REJECT.
 *
 * value_oracle: decode(s) must match expected for accepted strings. The buggy
 * rev accepts overlong c0 80 and echoes it instead of REJECT.
 *
 * Faithfulness limit: input domain is raw string-body bytes only. JSON escapes
 * (\\, \\uXXXX) and the CESU-8 surrogate-pair merge are out of the domain; the
 * bug under test lives in raw multibyte UTF-8 validation. */

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

static int hex_decode(const char *s, unsigned char *out) {
  int n = 0;
  while (s[2 * n] && s[2 * n + 1]) {
    int hi = hexval((unsigned char)s[2 * n]);
    int lo = hexval((unsigned char)s[2 * n + 1]);
    if (hi < 0 || lo < 0) return -1;
    out[n] = (unsigned char)((hi << 4) | lo);
    n++;
  }
  if (s[2 * n]) return -1;
  return n;
}


#if defined(LJSON_NOUTF8)

static int ljson_decode(const unsigned char *p, const unsigned char *e,
                        unsigned char *out, int *outn) {
  int oi = 0;
  while (p < e) {
    unsigned c = *p++;
    if (c == '"') break;
    if (c == '\\') return 1;
    if (c <= 0x1F) return 1;
    out[oi++] = (unsigned char)c;
  }
  *outn = oi;
  return 0;
}

#endif

static void print_str(const char *s) {
  int n = 0;
  while (s[n]) n++;
  sys_write(1, s, n);
}

static void print_hex(const unsigned char *b, int n) {
  static const char hexd[] = "0123456789abcdef";
  char out[1024];
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
  unsigned char in[256];
  int n = hex_decode(operand, in);
  if (n < 0) {
    print_str("REJECT\n");
    sys_exit(0);
  }
  unsigned char out[512];
  int outn = 0;
  if (ljson_decode(in, in + n, out, &outn))
    print_str("REJECT\n");
  else
    print_hex(out, outn);
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "call real_start\n");
}
