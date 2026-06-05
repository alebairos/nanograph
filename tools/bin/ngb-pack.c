#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>

static int read_file(const char *path, uint8_t **buf, size_t *len) {
  FILE *f = fopen(path, "rb");
  if (!f)
    return -1;
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return -1;
  }
  long sz = ftell(f);
  if (sz < 0) {
    fclose(f);
    return -1;
  }
  rewind(f);
  *buf = malloc((size_t)sz);
  if (!*buf) {
    fclose(f);
    return -1;
  }
  if (fread(*buf, 1, (size_t)sz, f) != (size_t)sz) {
    free(*buf);
    fclose(f);
    return -1;
  }
  fclose(f);
  *len = (size_t)sz;
  return 0;
}

static int write_file(const char *path, const uint8_t *buf, size_t len) {
  FILE *f = fopen(path, "wb");
  if (!f)
    return -1;
  if (fwrite(buf, 1, len, f) != len) {
    fclose(f);
    return -1;
  }
  fclose(f);
  return 0;
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <elf.bin> <out.ngb>\n", argv[0]);
    return 2;
  }
  uint8_t *elf = NULL;
  size_t elf_len = 0;
  if (read_file(argv[1], &elf, &elf_len) != 0) {
    fprintf(stderr, "ngb-pack: read %s failed\n", argv[1]);
    return 1;
  }
  uint8_t *out = NULL;
  size_t out_len = 0;
  NgbStatus st = ngb_pack_elf(elf, elf_len, NGB_ARCH_X86_64_LINUX_ELF, 1, &out,
                              &out_len);
  free(elf);
  if (st != NGB_OK) {
    fprintf(stderr, "ngb-pack: %s\n", ngb_status_str(st));
    return 1;
  }
  if (write_file(argv[2], out, out_len) != 0) {
    fprintf(stderr, "ngb-pack: write %s failed\n", argv[2]);
    free(out);
    return 1;
  }
  free(out);
  return 0;
}
