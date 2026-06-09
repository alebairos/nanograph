/* G39 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful C transcription of capnproto/kj libb64-derived base64 in
 * c++/src/kj/encoding.c++ (public domain libb64 core). Parent 9306bc0
 * silently skipped invalid and padding bytes; fix f3e0ed2 (PR #595, merge
 * 6a59486) reports hadErrors for non-whitespace outside [+/0-9A-Za-z=] and
 * for padding mistakes.
 *
 *   dec <b64>   decode; print lowercase hex of bytes or REJECT.
 *   enc <hex>   canonical base64 (no line breaks) or REJECT.
 *
 * round_trip: enc(dec(b)) == b for accepted b. Buggy decode accepts Zm9v@
 * (skips @), re-encodes to Zm9v != Zm9v@. */

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

static void print_str(const char *s) {
  long n = 0;
  while (s[n])
    n++;
  sys_write(1, s, n);
}

static void print_hex_bytes(const unsigned char *b, int n) {
  static const char d[] = "0123456789abcdef";
  char buf[256];
  int i = 0;
  for (int k = 0; k < n && i + 2 < (int)sizeof(buf); k++) {
    buf[i++] = d[(b[k] >> 4) & 0xf];
    buf[i++] = d[b[k] & 0xf];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}

typedef enum { step_A, step_B, step_C } enc_step;
typedef struct {
  enc_step step;
  char result;
} enc_state;

static char enc_value(char v) {
  static const char *tbl =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  if ((unsigned char)v > 63)
    return '=';
  return tbl[(unsigned char)v];
}

static int encode_block(const unsigned char *in, int len, char *out, enc_state *st) {
  const unsigned char *p = in;
  const unsigned char *end = in + len;
  char *c = out;
  char frag;
  char res = st->result;

  switch (st->step) {
  while (1) {
  case step_A:
    if (p == end) {
      st->result = res;
      st->step = step_A;
      return (int)(c - out);
    }
    frag = *p++;
    res = (char)((frag & 0xfc) >> 2);
    *c++ = enc_value(res);
    res = (char)((frag & 0x03) << 4);
  case step_B:
    if (p == end) {
      st->result = res;
      st->step = step_B;
      return (int)(c - out);
    }
    frag = *p++;
    res |= (char)((frag & 0xf0) >> 4);
    *c++ = enc_value(res);
    res = (char)((frag & 0x0f) << 2);
  case step_C:
    if (p == end) {
      st->result = res;
      st->step = step_C;
      return (int)(c - out);
    }
    frag = *p++;
    res |= (char)((frag & 0xc0) >> 6);
    *c++ = enc_value(res);
    res = (char)((frag & 0x3f));
    *c++ = enc_value(res);
  }
  }
  return (int)(c - out);
}

static int encode_end(char *out, enc_state *st) {
  char *c = out;
  switch (st->step) {
  case step_B:
    *c++ = enc_value(st->result);
    *c++ = '=';
    *c++ = '=';
    break;
  case step_C:
    *c++ = enc_value(st->result);
    *c++ = '=';
    break;
  default:
    break;
  }
  return (int)(c - out);
}

static int b64_encode(const unsigned char *in, int n, char *out, int cap) {
  enc_state st = {step_A, 0};
  char *c = out;
  int left = cap;
  int w = encode_block(in, n, c, &st);
  c += w;
  left -= w;
  if (left < 3)
    return -1;
  w = encode_end(c, &st);
  c += w;
  *c = 0;
  return (int)(c - out);
}

typedef enum { step_a, step_b, step_c, step_d } dec_step;

typedef struct {
  int had_errors;
  int n_padding;
  dec_step step;
  char plainchar;
} dec_state_strict;

typedef struct {
  dec_step step;
  char plainchar;
} dec_state_perm;

static int dec_value_strict(char c) {
  static const char tbl[] = {
      -3, -3, -3, -3, -3, -3, -3, -3, -3, -1, -1, -3, -1, -1, -3, -3, -3, -3, -3,
      -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -1, -3, -3, -3, -3, -3,
      -3, -3, -3, -3, -3, 62, -3, -3, -3, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60,
      61, -3, -3, -3, -2, -3, -3, -3, 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10,
      11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -3, -3, -3, -3, -3,
      -3, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44,
      45, 46, 47, 48, 49, 50, 51};
  if ((unsigned char)c >= sizeof(tbl))
    return -3;
  return tbl[(unsigned char)c];
}

static int decode_block_strict(const char *in, int len, unsigned char *out, dec_state_strict *st) {
  const char *p = in;
  const char *end = in + len;
  unsigned char *o = out;
  char frag;

  if (st->step != step_a)
    *o = (unsigned char)st->plainchar;

  switch (st->step) {
  while (1) {
  case step_a:
    do {
      if (p == end) {
        st->step = step_a;
        st->plainchar = 0;
        return (int)(o - out);
      }
      frag = (char)dec_value_strict(*p++);
      if (frag < -1)
        st->had_errors = 1;
    } while (frag < 0);
    st->plainchar = (char)((frag & 0x3f) << 2);
  case step_b:
    do {
      if (p == end) {
        st->step = step_b;
        st->plainchar = st->plainchar;
        st->had_errors = 1;
        return (int)(o - out);
      }
      frag = (char)dec_value_strict(*p++);
      if (frag < -1)
        st->had_errors = 1;
    } while (frag < 0);
    *o++ = (unsigned char)(st->plainchar | ((frag & 0x30) >> 4));
    st->plainchar = (char)((frag & 0x0f) << 4);
  case step_c:
    do {
      if (p == end) {
        st->step = step_c;
        st->plainchar = st->plainchar;
        if (st->n_padding == 1)
          st->had_errors = 1;
        return (int)(o - out);
      }
      frag = (char)dec_value_strict(*p++);
      if (frag < -2 || (frag == -2 && ++st->n_padding > 2))
        st->had_errors = 1;
    } while (frag < 0);
    if (st->n_padding > 0)
      st->had_errors = 1;
    *o++ = (unsigned char)(st->plainchar | ((frag & 0x3c) >> 2));
    st->plainchar = (char)((frag & 0x03) << 6);
  case step_d:
    do {
      if (p == end) {
        st->step = step_d;
        st->plainchar = st->plainchar;
        return (int)(o - out);
      }
      frag = (char)dec_value_strict(*p++);
      if (frag < -2 || (frag == -2 && ++st->n_padding > 1))
        st->had_errors = 1;
    } while (frag < 0);
    if (st->n_padding > 0)
      st->had_errors = 1;
    *o++ = (unsigned char)(st->plainchar | (frag & 0x3f));
  }
  }
  return (int)(o - out);
}

static int b64_decode_strict(const char *in, int len, unsigned char *out, int cap, int *err) {
  dec_state_strict st = {0, 0, step_a, 0};
  int n = decode_block_strict(in, len, out, &st);
  if (n > cap)
    return -1;
  *err = st.had_errors;
  return n;
}

static int dec_value_perm(char c) {
  static const char tbl[] = {
      62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -2, -1,
      -1, -1, 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17,
      18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31,
      32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51};
  c -= 43;
  if (c < 0 || c >= (char)sizeof(tbl))
    return -1;
  return tbl[(unsigned char)c];
}

static int decode_block_perm(const char *in, int len, unsigned char *out, dec_state_perm *st) {
  const char *p = in;
  const char *end = in + len;
  unsigned char *o = out;
  char frag;

  if (st->step != step_a)
    *o = (unsigned char)st->plainchar;

  switch (st->step) {
  while (1) {
  case step_a:
    do {
      if (p == end) {
        st->step = step_a;
        st->plainchar = 0;
        return (int)(o - out);
      }
      frag = (char)dec_value_perm(*p++);
    } while (frag < 0);
    st->plainchar = (char)((frag & 0x3f) << 2);
  case step_b:
    do {
      if (p == end) {
        st->step = step_b;
        st->plainchar = st->plainchar;
        return (int)(o - out);
      }
      frag = (char)dec_value_perm(*p++);
    } while (frag < 0);
    *o++ = (unsigned char)(st->plainchar | ((frag & 0x30) >> 4));
    st->plainchar = (char)((frag & 0x0f) << 4);
  case step_c:
    do {
      if (p == end) {
        st->step = step_c;
        st->plainchar = st->plainchar;
        return (int)(o - out);
      }
      frag = (char)dec_value_perm(*p++);
    } while (frag < 0);
    *o++ = (unsigned char)(st->plainchar | ((frag & 0x3c) >> 2));
    st->plainchar = (char)((frag & 0x03) << 6);
  case step_d:
    do {
      if (p == end) {
        st->step = step_d;
        st->plainchar = st->plainchar;
        return (int)(o - out);
      }
      frag = (char)dec_value_perm(*p++);
    } while (frag < 0);
    *o++ = (unsigned char)(st->plainchar | (frag & 0x3f));
  }
  }
  return (int)(o - out);
}

static int b64_decode_perm(const char *in, int len, unsigned char *out, int cap, int *err) {
  dec_state_perm st = {step_a, 0};
  int n = decode_block_perm(in, len, out, &st);
  if (n > cap)
    return -1;
  *err = 0;
  return n;
}

#if !defined(INVALID_OK)
static int b64_decode(const char *in, int len, unsigned char *out, int cap, int *err) {
  return b64_decode_strict(in, len, out, cap, err);
}
#endif

#if defined(INVALID_OK)
static int b64_decode(const char *in, int len, unsigned char *out, int cap, int *err) {
  return b64_decode_perm(in, len, out, cap, err);
}
#endif

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  if (mode[0] == 'd') {
    unsigned char buf[128];
    int err = 0;
    int n = 0;
    for (const char *s = operand; *s; s++)
      n++;
    int dn = b64_decode(operand, n, buf, (int)sizeof(buf), &err);
    if (dn < 0 || err)
      print_str("REJECT\n");
    else
      print_hex_bytes(buf, dn);
  } else if (mode[0] == 'e') {
    unsigned char buf[128];
    char out[256];
    int n = parse_hex(operand, buf, (int)sizeof(buf));
    if (n < 0 || b64_encode(buf, n, out, (int)sizeof(out)) < 0)
      print_str("REJECT\n");
    else
      print_str(out);
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
