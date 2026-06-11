/* G57 specimen. Freestanding Wyhash transcription from ziglang/zig std/hash/wyhash.zig.
 *
 * Parent 90fde14c update() dropped the last-16 tail copy when len>=48 and
 * remainder<16; fix f3fbdf2b (PR #16696).
 *
 *   flow <len> <seed|token>
 *
 * Small decimal seed: hash <len> bytes (one-shot) unless len==48 (partial token).
 * Token (leading '2'): continue <len> bytes from packed state, print final hash. */

#define PARTIAL_N 48

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

static void print_u64(unsigned long long n) {
  char buf[32];
  int i = 0;
  if (n == 0) {
    buf[i++] = '0';
  } else {
    char tmp[32];
    int j = 0;
    while (n > 0) {
      tmp[j++] = (char)('0' + (n % 10ULL));
      n /= 10ULL;
    }
    while (j > 0)
      buf[i++] = tmp[--j];
  }
  buf[i++] = '\n';
  sys_write(1, buf, i);
}


typedef struct {
  unsigned long long a;
  unsigned long long b;
  unsigned long long state[3];
  unsigned long long total_len;
  unsigned char buf[48];
  unsigned char buf_len;
  unsigned long long orig_seed;
} Wyhash;

static const unsigned long long secret[4] = {
    0xa0761d6478bd642fULL, 0xe7037ed1a0b428dbULL, 0x8ebc6af09c88c6e3ULL,
    0x589965cc75374cc3ULL,
};

static unsigned long long read_le(int bytes, const unsigned char *data) {
  unsigned long long v = 0;
  for (int i = bytes - 1; i >= 0; i--)
    v = (v << 8) | data[i];
  return v;
}

static void mum(unsigned long long *a, unsigned long long *b) {
  unsigned __int128 x = (unsigned __int128)(*a) * (unsigned __int128)(*b);
  *a = (unsigned long long)x;
  *b = (unsigned long long)(x >> 64);
}

static unsigned long long mix(unsigned long long a, unsigned long long b) {
  mum(&a, &b);
  return a ^ b;
}

static void wyhash_init(Wyhash *w, unsigned long long seed) {
  w->a = w->b = 0;
  w->total_len = 0;
  w->buf_len = 0;
  w->orig_seed = seed;
  w->state[0] = seed ^ mix(seed ^ secret[0], secret[1]);
  w->state[1] = w->state[0];
  w->state[2] = w->state[0];
}

static void gen_byte(unsigned long long seed, unsigned long long idx, unsigned char *out) {
  unsigned long long x = seed ^ (idx * 0x9e3779b97f4a7c15ULL);
  x ^= x >> 33;
  x *= 0xff51afd7ed558ccdULL;
  *out = (unsigned char)(x >> 56);
}

static void gen_block(unsigned long long seed, unsigned long long off, unsigned char *out,
                     unsigned long len) {
  for (unsigned long i = 0; i < len; i++)
    gen_byte(seed, off + i, out + i);
}

static void small_key(Wyhash *w, const unsigned char *input, int len) {
  if (len >= 4) {
    int end = len - 4;
    int quarter = (len >> 3) << 2;
    w->a = (read_le(4, input) << 32) | read_le(4, input + quarter);
    w->b = (read_le(4, input + end) << 32) | read_le(4, input + end - quarter);
  } else if (len > 0) {
    w->a = ((unsigned long long)input[0] << 16) |
           ((unsigned long long)input[len >> 1] << 8) | input[len - 1];
    w->b = 0;
  } else {
    w->a = w->b = 0;
  }
}

static void round48(Wyhash *w, const unsigned char input[48]) {
  for (int i = 0; i < 3; i++) {
    unsigned long long a = read_le(8, input + 8 * (2 * i));
    unsigned long long b = read_le(8, input + 8 * (2 * i + 1));
    w->state[i] = mix(a ^ secret[i + 1], b ^ w->state[i]);
  }
}

static void wyhash_update(Wyhash *w, const unsigned char *input, unsigned long len) {
  w->total_len += len;
  if (len <= (unsigned long)(48 - w->buf_len)) {
    for (unsigned long i = 0; i < len; i++)
      w->buf[w->buf_len + i] = input[i];
    w->buf_len = (unsigned char)(w->buf_len + len);
    return;
  }

  unsigned long i = 0;
  if (w->buf_len > 0) {
    i = (unsigned long)(48 - w->buf_len);
    for (unsigned long j = 0; j < i; j++)
      w->buf[w->buf_len + j] = input[j];
    round48(w, w->buf);
    w->buf_len = 0;
  }

  while (i + 48 < len) {
    round48(w, input + i);
    i += 48;
  }

  const unsigned char *remaining = input + i;
  unsigned long rem = len - i;
  for (unsigned long j = 0; j < rem; j++)
    w->buf[j] = remaining[j];
  w->buf_len = (unsigned char)rem;
}

static void final0(Wyhash *w) { w->state[0] ^= w->state[1] ^ w->state[2]; }

static void final1(Wyhash *w, const unsigned char *input_lb, int lb_len, int start_pos) {
  const unsigned char *input = input_lb + start_pos;
  int input_len = lb_len - start_pos;
  int i = 0;
  while (i + 16 < input_len) {
    w->state[0] = mix(read_le(8, input + i) ^ secret[1], read_le(8, input + i + 8) ^ w->state[0]);
    i += 16;
  }
  w->a = read_le(8, input_lb + lb_len - 16);
  w->b = read_le(8, input_lb + lb_len - 8);
}

static unsigned long long final2(Wyhash *w) {
  w->a ^= secret[1];
  w->b ^= w->state[0];
  mum(&w->a, &w->b);
  return mix(w->a ^ secret[0] ^ w->total_len, w->b ^ secret[1]);
}

static unsigned long long wyhash_final(Wyhash *w) {
  Wyhash tmp = *w;
  const unsigned char *input = tmp.buf;
  int input_len = tmp.buf_len;

  if (tmp.total_len <= 16) {
    small_key(&tmp, input, input_len);
  } else {
    int offset = 0;
    unsigned char scratch[16];
    if (tmp.buf_len < 16) {
      int rem = 16 - tmp.buf_len;
      for (int j = 0; j < rem; j++)
        scratch[j] = tmp.buf[48 - rem + j];
      for (int j = 0; j < tmp.buf_len; j++)
        scratch[rem + j] = tmp.buf[j];
      input = scratch;
      input_len = 16;
      offset = rem;
    }
    final0(&tmp);
    final1(&tmp, input, input_len, offset);
  }
  return final2(&tmp);
}

static unsigned long long wyhash_hash(unsigned long long seed, unsigned long len) {
  Wyhash w;
  wyhash_init(&w, seed);
  unsigned char block[512];
  unsigned long off = 0;
  while (off < len) {
    unsigned long chunk = len - off;
    if (chunk > sizeof(block))
      chunk = sizeof(block);
    gen_block(seed, off, block, chunk);
    wyhash_update(&w, block, chunk);
    off += chunk;
  }
  return wyhash_final(&w);
}

static void put_u20(char *out, int *pos, int cap, unsigned long long v) {
  for (int d = 19; d >= 0; d--) {
    unsigned long long div = 1;
    for (int e = 0; e < d; e++)
      div *= 10ULL;
    if (*pos + 1 >= cap)
      return;
    out[(*pos)++] = (char)('0' + ((v / div) % 10ULL));
  }
}

static void pack_token(const Wyhash *w, char *out, int cap) {
  int pos = 0;
  if (pos + 1 >= cap)
    return;
  out[pos++] = '2';
  for (int k = 0; k < 3; k++)
    put_u20(out, &pos, cap, w->state[k]);
  put_u20(out, &pos, cap, w->a);
  put_u20(out, &pos, cap, w->b);
  put_u20(out, &pos, cap, w->total_len);
  put_u20(out, &pos, cap, w->orig_seed);
  if (pos + 3 >= cap)
    return;
  out[pos++] = (char)('0' + (w->buf_len / 100) % 10);
  out[pos++] = (char)('0' + (w->buf_len / 10) % 10);
  out[pos++] = (char)('0' + w->buf_len % 10);
  for (int i = 0; i < 48; i++) {
    if (pos + 3 >= cap)
      return;
    out[pos++] = (char)('0' + (w->buf[i] / 100) % 10);
    out[pos++] = (char)('0' + (w->buf[i] / 10) % 10);
    out[pos++] = (char)('0' + w->buf[i] % 10);
  }
  out[pos++] = '\n';
  sys_write(1, out, pos);
}

static int unpack_token(const char *s, Wyhash *w) {
  if (s[0] != '2')
    return -1;
  s++;
  for (int k = 0; k < 3; k++) {
    unsigned long long v = 0;
    for (int d = 0; d < 20; d++) {
      if (*s < '0' || *s > '9')
        return -1;
      v = v * 10ULL + (unsigned long long)(*s - '0');
      s++;
    }
    w->state[k] = v;
  }
  unsigned long long *fields[4] = {&w->a, &w->b, &w->total_len, &w->orig_seed};
  for (int f = 0; f < 4; f++) {
    unsigned long long v = 0;
    for (int d = 0; d < 20; d++) {
      if (*s < '0' || *s > '9')
        return -1;
      v = v * 10ULL + (unsigned long long)(*s - '0');
      s++;
    }
    *fields[f] = v;
  }
  int bl = 0;
  for (int d = 0; d < 3; d++) {
    if (*s < '0' || *s > '9')
      return -1;
    bl = bl * 10 + (*s - '0');
    s++;
  }
  if (bl < 0 || bl > 48)
    return -1;
  w->buf_len = (unsigned char)bl;
  for (int i = 0; i < 48; i++) {
    int b = 0;
    for (int d = 0; d < 3; d++) {
      if (*s < '0' || *s > '9')
        return -1;
      b = b * 10 + (*s - '0');
      s++;
    }
    w->buf[i] = (unsigned char)b;
  }
  return 0;
}

static void flow_partial(unsigned long len, unsigned long long seed) {
  Wyhash w;
  wyhash_init(&w, seed);
  unsigned char block[512];
  unsigned long off = 0;
  while (off < len) {
    unsigned long chunk = len - off;
    if (chunk > sizeof(block))
      chunk = sizeof(block);
    gen_block(seed, off, block, chunk);
    wyhash_update(&w, block, chunk);
    off += chunk;
  }
  char tok[512];
  pack_token(&w, tok, (int)sizeof(tok));
}

static void flow_continue(unsigned long len, const char *token) {
  Wyhash w;
  if (unpack_token(token, &w) != 0)
    sys_exit(1);
  unsigned char block[512];
  unsigned long off = w.total_len;
  unsigned long end = off + len;
  while (off < end) {
    unsigned long chunk = end - off;
    if (chunk > sizeof(block))
      chunk = sizeof(block);
    gen_block(w.orig_seed, off, block, chunk);
    wyhash_update(&w, block, chunk);
    off += chunk;
  }
  print_u64(wyhash_final(&w));
}

__attribute__((noreturn))
void real_start(long argc, const char *mode, const char *len_s, const char *arg) {
  if (argc < 4)
    sys_exit(1);
  if (mode[0] != 'f' || mode[1] != 'l' || mode[2] != 'o' || mode[3] != 'w' || mode[4] != '\0')
    sys_exit(1);

  unsigned long len = (unsigned long)parse_u(len_s);
  if (arg[0] == '2') {
    flow_continue(len, arg);
    sys_exit(0);
  }

  unsigned long long seed = (unsigned long long)parse_u(arg);
  if (len == PARTIAL_N) {
    flow_partial(len, seed);
    sys_exit(0);
  }

  print_u64(wyhash_hash(seed, len));
  sys_exit(0);
}

__attribute__((naked))
void _start(void) {
  __asm__("mov (%rsp), %rdi\n"
          "mov 16(%rsp), %rsi\n"
          "mov 24(%rsp), %rdx\n"
          "mov 32(%rsp), %rcx\n"
          "call real_start\n");
}
