/* G84 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * Faithful transcription of CPython 3.12.0 Modules/binascii.c:
 *   binascii_a2b_base64_impl (strict_mode=TRUE)
 *   binascii_b2a_base64_impl (newline=FALSE)
 *
 *   dec <b64ascii>   strict decode; lowercase hex or REJECT.
 *   enc <hex>        standard base64 (no trailing newline) or REJECT.
 *
 * round_trip: enc(dec(b)) == b for accepted b. */

#define BASE64_PAD '='

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

/* CPython table_a2b_base64 (invalid entries are 255). */
static const unsigned char table_a2b_base64[256] = {
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 62,  255, 255, 255, 63,
    52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  255, 255, 255, 0,   255, 255,
    255, 0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,
    15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  255, 255, 255, 255, 255,
    255, 26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,
    41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51,  255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
};

static const unsigned char table_b2a_base64[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/* binascii_a2b_base64_impl, strict_mode=TRUE. Returns decoded length or -1. */
static int b64_decode_strict(const unsigned char *ascii_data, int ascii_len,
                             unsigned char *bin_data, int bin_cap) {
  int strict_mode = 1;
  char padding_started = 0;
  unsigned char *bin_data_start = bin_data;
  unsigned char *bin_end = bin_data + bin_cap;

  if (strict_mode && ascii_len > 0 && ascii_data[0] == BASE64_PAD)
    return -1;

  int quad_pos = 0;
  unsigned char leftchar = 0;
  int pads = 0;

  for (int i = 0; i < ascii_len; i++) {
    unsigned char this_ch = ascii_data[i];

    if (this_ch == BASE64_PAD) {
      padding_started = 1;

      if (quad_pos >= 2 && quad_pos + ++pads >= 4) {
        if (strict_mode && i + 1 < ascii_len)
          return -1;
        goto done;
      }
      continue;
    }

    this_ch = table_a2b_base64[this_ch];
    if (this_ch >= 64) {
      if (strict_mode)
        return -1;
      continue;
    }

    if (strict_mode && padding_started)
      return -1;
    pads = 0;

    switch (quad_pos) {
    case 0:
      quad_pos = 1;
      leftchar = this_ch;
      break;
    case 1:
      quad_pos = 2;
      if (bin_data >= bin_end)
        return -1;
      *bin_data++ = (leftchar << 2) | (this_ch >> 4);
      leftchar = this_ch & 0x0f;
      break;
    case 2:
      quad_pos = 3;
      if (bin_data >= bin_end)
        return -1;
      *bin_data++ = (leftchar << 4) | (this_ch >> 2);
      leftchar = this_ch & 0x03;
      break;
    case 3:
      quad_pos = 0;
      if (bin_data >= bin_end)
        return -1;
      *bin_data++ = (leftchar << 6) | (this_ch);
      leftchar = 0;
      break;
    }
  }

  if (quad_pos != 0)
    return -1;

done:
  return (int)(bin_data - bin_data_start);
}

/* binascii_b2a_base64_impl, newline=FALSE. Returns encoded length or -1. */
static int b64_encode(const unsigned char *bin_data, int bin_len, char *ascii_data,
                      int ascii_cap) {
  char *ascii_start = ascii_data;
  char *ascii_end = ascii_data + ascii_cap;
  int leftbits = 0;
  unsigned int leftchar = 0;

  for (; bin_len > 0; bin_len--, bin_data++) {
    leftchar = (leftchar << 8) | *bin_data;
    leftbits += 8;

    while (leftbits >= 6) {
      unsigned char this_ch = (leftchar >> (leftbits - 6)) & 0x3f;
      leftbits -= 6;
      if (ascii_data >= ascii_end)
        return -1;
      *ascii_data++ = table_b2a_base64[this_ch];
    }
  }

  if (leftbits == 2) {
    if (ascii_data + 3 > ascii_end)
      return -1;
    *ascii_data++ = table_b2a_base64[(leftchar & 3) << 4];
    *ascii_data++ = BASE64_PAD;
    *ascii_data++ = BASE64_PAD;
  } else if (leftbits == 4) {
    if (ascii_data + 2 > ascii_end)
      return -1;
    *ascii_data++ = table_b2a_base64[(leftchar & 0xf) << 2];
    *ascii_data++ = BASE64_PAD;
  }

  if (ascii_data >= ascii_end)
    return -1;
  *ascii_data = 0;
  return (int)(ascii_data - ascii_start);
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *operand) {
  if (argc < 3)
    sys_exit(1);

  if (mode[0] == 'd') {
    unsigned char buf[256];
    int n = 0;
    for (const char *s = operand; *s; s++)
      n++;
    int dn = b64_decode_strict((const unsigned char *)operand, n, buf, (int)sizeof(buf));
    if (dn < 0)
      print_str("REJECT\n");
    else
      print_hex_bytes(buf, dn);
  } else if (mode[0] == 'e') {
    unsigned char buf[256];
    char out[512];
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
