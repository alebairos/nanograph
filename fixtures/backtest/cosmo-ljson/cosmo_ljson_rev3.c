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


#define ASCII     0
#define C0        1
#define DQUOTE    2
#define BACKSLASH 3
#define UTF8_2    4
#define UTF8_3    5
#define UTF8_4    6
#define C1        7
#define UTF8_3_E0 8
#define UTF8_3_ED 9
#define UTF8_4_F0 10
#define BADUTF8   11
#define EVILUTF8  12

static const unsigned char kJsonStr[256] = {
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,
    0,  0,  2,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  3,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,
    7,  7,  7,  7,  7,  7,  7,  7,
    7,  7,  7,  7,  7,  7,  7,  7,
    7,  7,  7,  7,  7,  7,  7,  7,
    7,  7,  7,  7,  7,  7,  7,  7,
    11, 11, 11, 11, 11, 11, 11, 11,
    11, 11, 11, 11, 11, 11, 11, 11,
    11, 11, 11, 11, 11, 11, 11, 11,
    11, 11, 11, 11, 11, 11, 11, 11,
    12, 12, 4,  4,  4,  4,  4,  4,
    4,  4,  4,  4,  4,  4,  4,  4,
    4,  4,  4,  4,  4,  4,  4,  4,
    4,  4,  4,  4,  4,  4,  4,  4,
    8,  5,  5,  5,  5,  5,  5,  5,
    5,  5,  5,  5,  5,  9,  5,  5,
    10, 6,  6,  6,  6,  11, 11, 11,
    11, 11, 11, 11, 11, 11, 11, 11,
};

static int is_cont(unsigned char c) { return (c & 0300) == 0200; }

static void emit_cp(unsigned c, unsigned char *out, int *oi) {
  if (c <= 0x7f) {
    out[(*oi)++] = (unsigned char)c;
  } else if (c <= 0x7ff) {
    out[(*oi)++] = (unsigned char)(0300 | (c >> 6));
    out[(*oi)++] = (unsigned char)(0200 | (c & 077));
  } else if (c <= 0xffff) {
    out[(*oi)++] = (unsigned char)(0340 | (c >> 12));
    out[(*oi)++] = (unsigned char)(0200 | ((c >> 6) & 077));
    out[(*oi)++] = (unsigned char)(0200 | (c & 077));
  } else {
    out[(*oi)++] = (unsigned char)(0360 | (c >> 18));
    out[(*oi)++] = (unsigned char)(0200 | ((c >> 12) & 077));
    out[(*oi)++] = (unsigned char)(0200 | ((c >> 6) & 077));
    out[(*oi)++] = (unsigned char)(0200 | (c & 077));
  }
}

static int ljson_decode(const unsigned char *p, const unsigned char *e,
                        unsigned char *out, int *outn) {
  int oi = 0;
  while (p < e) {
    unsigned c = *p++;
    switch (kJsonStr[c]) {
      case ASCII:
        out[oi++] = (unsigned char)c;
        continue;
      case DQUOTE:
        goto done;
      case UTF8_2:
        if (p < e && is_cont(p[0])) {
          c = (c & 037) << 6 | (p[0] & 077);
          p += 1;
        } else {
          return 1;
        }
        break;
      case UTF8_3_E0:
        if (p + 2 <= e && (p[0] & 0377) < 0240 && is_cont(p[0]) && is_cont(p[1]))
          return 1;
        goto three;
      case UTF8_3_ED:
        if (p + 2 <= e && (p[0] & 0377) >= 0240)
          return 1;
        goto three;
      case UTF8_3:
      three:
        if (p + 2 <= e && is_cont(p[0]) && is_cont(p[1])) {
          c = (c & 017) << 12 | (p[0] & 077) << 6 | (p[1] & 077);
          p += 2;
        } else {
          return 1;
        }
        break;
      case UTF8_4_F0:
        if (p + 3 <= e && (p[0] & 0377) < 0220 && is_cont(p[0]) &&
            is_cont(p[1]) && is_cont(p[2]))
          return 1;
        goto four;
      case UTF8_4:
      four:
        if (p + 3 <= e && is_cont(p[0]) && is_cont(p[1]) && is_cont(p[2])) {
          c = (c & 007) << 18 | (p[0] & 077) << 12 | (p[1] & 077) << 6 |
              (p[2] & 077);
          p += 3;
          if (c > 0x10FFFF) return 1;
        } else {
          return 1;
        }
        break;
      default:
        return 1;
    }
    emit_cp(c, out, &oi);
  }
done:
  *outn = oi;
  return 0;
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
