/* G56 specimen. Freestanding x86_64 Linux ELF, no libc.
 *
 * C transcription of marshallpierce/rust-base64 decode_helper stage 4
 * (InvalidLastSymbol) and STANDARD encode/decode tables. Parent 95edf364
 * accepted trailing unused bits (iYV=); fix f6915a3 rejects.
 *
 *   dec <b64>   decode; print lowercase hex of bytes or REJECT.
 *   enc <hex>   canonical base64 (no line breaks) or REJECT.
 *
 * round_trip: enc(dec(b)) == b for accepted b. */

#define INVALID_VALUE 255
#define INPUT_CHUNK_LEN 8
#define DECODED_CHUNK_LEN 6

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

static unsigned char decode_table[256];
static const char encode_table[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static void init_tables(void) {
  for (int i = 0; i < 256; i++)
    decode_table[i] = INVALID_VALUE;
  for (int i = 0; i < 64; i++)
    decode_table[(unsigned char)encode_table[i]] = (unsigned char)i;
}

static char enc_value(unsigned char v) {
  if (v > 63)
    return '=';
  return encode_table[v];
}

static int b64_encode(const unsigned char *in, int n, char *out, int cap) {
  int o = 0;
  int i = 0;
  while (i + 3 <= n) {
    unsigned v = ((unsigned)in[i] << 16) | ((unsigned)in[i + 1] << 8) | (unsigned)in[i + 2];
    if (o + 4 > cap)
      return -1;
    out[o++] = enc_value((unsigned char)(v >> 18));
    out[o++] = enc_value((unsigned char)((v >> 12) & 0x3f));
    out[o++] = enc_value((unsigned char)((v >> 6) & 0x3f));
    out[o++] = enc_value((unsigned char)(v & 0x3f));
    i += 3;
  }
  if (i < n) {
    unsigned v = (unsigned)in[i] << 16;
    if (i + 1 < n)
      v |= (unsigned)in[i + 1] << 8;
    if (o + 4 > cap)
      return -1;
    out[o++] = enc_value((unsigned char)(v >> 18));
    out[o++] = enc_value((unsigned char)((v >> 12) & 0x3f));
    if (i + 1 < n)
      out[o++] = enc_value((unsigned char)((v >> 6) & 0x3f));
    else
      out[o++] = '=';
    out[o++] = '=';
  }
  if (o >= cap)
    return -1;
  out[o] = 0;
  return o;
}

static int decode_chunk_precise(const unsigned char *input, unsigned char *output) {
  unsigned long long accum = 0;
  for (int i = 0; i < 8; i++) {
    unsigned char m = decode_table[input[i]];
    if (m == INVALID_VALUE)
      return -1;
    accum |= (unsigned long long)m << (58 - i * 6);
  }
  output[0] = (unsigned char)(accum >> 58);
  output[1] = (unsigned char)(accum >> 52);
  output[2] = (unsigned char)(accum >> 46);
  output[3] = (unsigned char)(accum >> 40);
  output[4] = (unsigned char)(accum >> 34);
  output[5] = (unsigned char)(accum >> 28);
  return 0;
}

static int decode_helper(const unsigned char *input, int len, unsigned char *output, int cap) {
  if (len == 0)
    return 0;
  if (len % 4 == 1)
    return -1;

  int num_chunks = (len + INPUT_CHUNK_LEN - 1) / INPUT_CHUNK_LEN;
  int input_index = 0;
  int output_index = 0;

  for (int c = 1; c < num_chunks; c++) {
    if (input_index + INPUT_CHUNK_LEN > len || output_index + DECODED_CHUNK_LEN > cap)
      return -1;
    if (decode_chunk_precise(input + input_index, output + output_index) < 0)
      return -1;
    input_index += INPUT_CHUNK_LEN;
    output_index += DECODED_CHUNK_LEN;
  }

  unsigned long long leftover_bits = 0;
  int morsels_in_leftover = 0;
  int padding_bytes = 0;
  int first_padding_index = 0;
  int start_of_leftovers = input_index;

  for (int i = 0; start_of_leftovers + i < len; i++) {
    unsigned char b = input[start_of_leftovers + i];

    if (b == 0x3d) {
      if (i % 4 < 2)
        return -1;
      if (padding_bytes == 0)
        first_padding_index = i;
      padding_bytes++;
      continue;
    }

    if (padding_bytes > 0)
      return -1;

    int shift = 64 - (morsels_in_leftover + 1) * 6;
    unsigned char morsel = decode_table[b];
    if (morsel == INVALID_VALUE)
      return -1;

    leftover_bits |= (unsigned long long)morsel << shift;
    morsels_in_leftover++;
  }

  int leftover_bits_ready_to_append;
  switch (morsels_in_leftover) {
  case 0:
    leftover_bits_ready_to_append = 0;
    break;
  case 2:
    leftover_bits_ready_to_append = 8;
    break;
  case 3:
    leftover_bits_ready_to_append = 16;
    break;
  case 4:
    leftover_bits_ready_to_append = 24;
    break;
  case 6:
    leftover_bits_ready_to_append = 32;
    break;
  case 7:
    leftover_bits_ready_to_append = 40;
    break;
  case 8:
    leftover_bits_ready_to_append = 48;
    break;
  default:
    return -1;
  }


  int leftover_bits_appended_to_buf = 0;
  while (leftover_bits_appended_to_buf < leftover_bits_ready_to_append) {
    if (output_index >= cap)
      return -1;
    unsigned char selected_bits =
        (unsigned char)(leftover_bits >> (56 - leftover_bits_appended_to_buf));
    output[output_index++] = selected_bits;
    leftover_bits_appended_to_buf += 8;
  }

  return output_index;
}

static int b64_decode(const char *in, int len, unsigned char *out, int cap, int *err) {
  init_tables();
  int n = decode_helper((const unsigned char *)in, len, out, cap);
  if (n < 0) {
    *err = 1;
    return -1;
  }
  *err = 0;
  return n;
}

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
    init_tables();
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
