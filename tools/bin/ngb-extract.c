#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <file.ngb> <out_elf>\n", argv[0]);
    return 2;
  }
  FILE *f = fopen(argv[1], "rb");
  if (!f)
    return 1;
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  rewind(f);
  uint8_t *buf = malloc((size_t)sz);
  if (!buf || fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
    free(buf);
    fclose(f);
    return 1;
  }
  fclose(f);
  if (sz < 64 || memcmp(buf, "NGB\x00", 4) != 0)
    return 1;
  uint32_t off = (uint32_t)buf[12] | ((uint32_t)buf[13] << 8) |
                 ((uint32_t)buf[14] << 16) | ((uint32_t)buf[15] << 24);
  uint32_t len = (uint32_t)buf[16] | ((uint32_t)buf[17] << 8) |
                 ((uint32_t)buf[18] << 16) | ((uint32_t)buf[19] << 24);
  if ((uint64_t)off + len > (size_t)sz)
    return 1;
  FILE *out = fopen(argv[2], "wb");
  if (!out)
    return 1;
  fwrite(buf + off, 1, len, out);
  fclose(out);
  free(buf);
  return 0;
}
