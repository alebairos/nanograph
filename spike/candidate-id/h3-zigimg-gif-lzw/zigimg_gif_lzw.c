/* H3 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * C transcription of zigimg/zigimg GIF LZW decode in src/gif/lzw.zig.
 * Parent 0dd86499 lets next_code grow past the 4095 table limit when the
 * stream never sends a clear code; fix 9cab2519 (PR #329) guards the limit.
 *
 *   enc <hex>   LZW-compress bytes; packed code stream as lowercase hex.
 *   dec <hex>   LZW-decompress packed code stream; bytes as lowercase hex.
 *
 * round_trip: enc(dec(b)) == b for accepted b; the lax rev accepts overflow
 * streams and corrupts them.
 *
 * NO_CODE_LIMIT omits only the honest decoder's table-overflow guard. */

#define LZW_TABLE_SIZE 4096
#define CLEAR_CODE 256
#define EOI_CODE 257
#define FIRST_CODE 258
#define MAX_CODE_BITS 12

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

typedef struct {
  unsigned short prefix;
  unsigned char suffix;
} dict_entry;

typedef struct {
  unsigned char *buf;
  int cap;
  int nbits;
} bit_writer;

typedef struct {
  const unsigned char *buf;
  int nbytes;
  int pos;
} bit_reader;

static void bitw_init(bit_writer *w, unsigned char *buf, int cap) {
  w->buf = buf;
  w->cap = cap;
  w->nbits = 0;
}

static int bitw_write(bit_writer *w, unsigned code, int width) {
  for (int i = 0; i < width; i++) {
    int bitpos = w->nbits;
    int byte_idx = bitpos / 8;
    int bit_idx = bitpos % 8;
    if (byte_idx >= w->cap)
      return -1;
    if (code & (1U << i))
      w->buf[byte_idx] |= (unsigned char)(1U << bit_idx);
    w->nbits++;
  }
  return 0;
}

static int bitw_bytes(bit_writer *w) {
  int n = w->nbits / 8;
  if (w->nbits % 8)
    n++;
  return n;
}

static void bitr_init(bit_reader *r, const unsigned char *buf, int nbytes) {
  r->buf = buf;
  r->nbytes = nbytes;
  r->pos = 0;
}

static int bitr_read(bit_reader *r, int width, unsigned *code_out) {
  unsigned code = 0;
  for (int i = 0; i < width; i++) {
    int bitpos = r->pos + i;
    int byte_idx = bitpos / 8;
    int bit_idx = bitpos % 8;
    if (byte_idx >= r->nbytes)
      return -1;
    if (r->buf[byte_idx] & (unsigned char)(1U << bit_idx))
      code |= (1U << i);
  }
  r->pos += width;
  *code_out = code;
  return 0;
}

static void lzw_reset_table(dict_entry *table, int *next_code, int *code_width) {
  for (int i = 0; i < 256; i++) {
    table[i].prefix = (unsigned short)i;
    table[i].suffix = (unsigned char)i;
  }
  *next_code = FIRST_CODE;
  *code_width = 9;
}

static int dict_find(const dict_entry *table, int next_code, unsigned short prefix,
                     unsigned char suffix) {
  for (int c = FIRST_CODE; c < next_code; c++) {
    if (table[c].prefix == prefix && table[c].suffix == suffix)
      return c;
  }
  return -1;
}

static int lzw_encode(const unsigned char *in, int in_len, unsigned char *out, int out_cap) {
  dict_entry table[LZW_TABLE_SIZE];
  bit_writer bw;
  int next_code;
  int code_width;

  bitw_init(&bw, out, out_cap);
  lzw_reset_table(table, &next_code, &code_width);

  if (bitw_write(&bw, CLEAR_CODE, code_width) < 0)
    return -1;

  if (in_len == 0) {
    if (bitw_write(&bw, EOI_CODE, code_width) < 0)
      return -1;
    return bitw_bytes(&bw);
  }

  unsigned short current = in[0];
  for (int i = 1; i < in_len; i++) {
    unsigned char b = in[i];
    int found = dict_find(table, next_code, current, b);
    if (found >= 0) {
      current = (unsigned short)found;
      continue;
    }

    if (bitw_write(&bw, current, code_width) < 0)
      return -1;

    if (next_code >= LZW_TABLE_SIZE) {
      if (bitw_write(&bw, CLEAR_CODE, code_width) < 0)
        return -1;
      lzw_reset_table(table, &next_code, &code_width);
    } else {
      table[next_code].prefix = current;
      table[next_code].suffix = b;
      next_code++;
      if (next_code == (1 << code_width) && code_width < MAX_CODE_BITS)
        code_width++;
    }

    current = b;
  }

  if (bitw_write(&bw, current, code_width) < 0)
    return -1;
  if (bitw_write(&bw, EOI_CODE, code_width) < 0)
    return -1;
  return bitw_bytes(&bw);
}

static int dict_unwind(const dict_entry *table, unsigned short code, unsigned char *stack,
                       int stack_cap) {
  int len = 0;
  unsigned short c = code;
  while (c >= FIRST_CODE) {
    if (len >= stack_cap)
      return -1;
    stack[len++] = table[c].suffix;
    c = table[c].prefix;
    if (c >= LZW_TABLE_SIZE)
      return -1;
  }
  if (len >= stack_cap)
    return -1;
  stack[len++] = (unsigned char)c;
  return len;
}

static int lzw_decode(const unsigned char *in, int in_len, unsigned char *out, int out_cap) {
  dict_entry table[LZW_TABLE_SIZE];
  bit_reader br;
  int next_code;
  int code_width;
  unsigned char stack[LZW_TABLE_SIZE];
  int stack_len;
  unsigned prev_code = 0;
  int have_prev = 0;

  bitr_init(&br, in, in_len);
  lzw_reset_table(table, &next_code, &code_width);

  unsigned code;
  if (bitr_read(&br, code_width, &code) < 0)
    return -1;
  if (code != CLEAR_CODE)
    return -1;

  if (bitr_read(&br, code_width, &code) < 0)
    return -1;

  int out_len = 0;
  while (1) {
    if (code == EOI_CODE)
      break;
    if (code == CLEAR_CODE) {
      lzw_reset_table(table, &next_code, &code_width);
      have_prev = 0;
      if (bitr_read(&br, code_width, &code) < 0)
        return -1;
      continue;
    }

    if (code >= (unsigned)next_code && code != (unsigned)next_code)
      return -1;

    unsigned char first_byte;
    if (code < FIRST_CODE) {
      first_byte = (unsigned char)code;
      if (out_len >= out_cap)
        return -1;
      out[out_len++] = first_byte;
    } else if (code == (unsigned)next_code) {
      if (!have_prev)
        return -1;
      stack_len = dict_unwind(table, (unsigned short)prev_code, stack, LZW_TABLE_SIZE);
      if (stack_len < 0)
        return -1;
      first_byte = stack[stack_len - 1];
      if (out_len + stack_len + 1 > out_cap)
        return -1;
      for (int i = stack_len - 1; i >= 0; i--)
        out[out_len++] = stack[i];
      out[out_len++] = first_byte;
    } else {
      stack_len = dict_unwind(table, (unsigned short)code, stack, LZW_TABLE_SIZE);
      if (stack_len < 0)
        return -1;
      first_byte = stack[stack_len - 1];
      if (out_len + stack_len > out_cap)
        return -1;
      for (int i = stack_len - 1; i >= 0; i--)
        out[out_len++] = stack[i];
    }

    if (have_prev) {
#if !defined(NO_CODE_LIMIT)
      if (next_code >= LZW_TABLE_SIZE)
        return -1;
#else
      if (next_code >= LZW_TABLE_SIZE)
        next_code = FIRST_CODE;
#endif
      table[next_code].prefix = (unsigned short)prev_code;
      table[next_code].suffix = first_byte;
      next_code++;
      if (next_code == (1 << code_width) && code_width < MAX_CODE_BITS)
        code_width++;
    }

    prev_code = code;
    have_prev = 1;

    if (bitr_read(&br, code_width, &code) < 0)
      return -1;
  }

  return out_len;
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);
  if (mode[0] == 'e') {
    static unsigned char inbuf[4096];
    static unsigned char outbuf[8192];
    int n = parse_hex(operand, inbuf, (int)sizeof(inbuf));
    int en = lzw_encode(inbuf, n, outbuf, (int)sizeof(outbuf));
    if (n < 0 || en < 0)
      print_str("REJECT\n");
    else
      print_hex_bytes(outbuf, en);
  } else if (mode[0] == 'd') {
    /* A no-clear overflow stream needs ~5.5 KB of packed codes (3838
     * insertions); 4096 would make the guarded path unreachable. */
    static unsigned char inbuf[8192];
    static unsigned char outbuf[4096];
    int n = parse_hex(operand, inbuf, (int)sizeof(inbuf));
    int dn = lzw_decode(inbuf, n, outbuf, (int)sizeof(outbuf));
    if (n < 0 || dn < 0)
      print_str("REJECT\n");
    else
      print_hex_bytes(outbuf, dn);
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
