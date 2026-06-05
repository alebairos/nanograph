#if defined(__linux__)
#define _POSIX_C_SOURCE 200809L
#endif

#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static const NgbNodeSpec PRINT_42_NODES[] = {
    {1, 0, 15},
    {2, 15, 7},
    {3, 22, 9},
    {4, 31, 3},
};

static int write_bytes(const char *path, const uint8_t *data, size_t len) {
  FILE *f = fopen(path, "wb");
  if (!f)
    return -1;
  if (fwrite(data, 1, len, f) != len) {
    fclose(f);
    return -1;
  }
  fclose(f);
  return 0;
}

static int write_hex(const char *path, const uint8_t *data, size_t len) {
  FILE *f = fopen(path, "w");
  if (!f)
    return -1;
  for (size_t i = 0; i < len; i += 16) {
    fprintf(f, "%08zx  ", i);
    size_t n = len - i < 16 ? len - i : 16;
    for (size_t j = 0; j < n; j++)
      fprintf(f, "%02x%s", data[i + j], j + 1 < n ? " " : "");
    fprintf(f, "\n");
  }
  fclose(f);
  return 0;
}

int main(int argc, char **argv) {
  int print_hash = 0;
  int print_ms = 0;
  int write_fixtures = 1;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--print-hash") == 0)
      print_hash = 1;
    if (strcmp(argv[i], "--print-ms") == 0)
      print_ms = 1;
    if (strcmp(argv[i], "--no-write") == 0)
      write_fixtures = 0;
  }

  struct timespec t0 = {0, 0};
  if (print_ms)
    clock_gettime(CLOCK_MONOTONIC, &t0);

  uint8_t elf[512];
  size_t elf_len = ngb_print_42_elf_build(elf, sizeof(elf));
  if (elf_len == 0) {
    fprintf(stderr, "print-42-fixture: elf build failed\n");
    return 1;
  }

  uint8_t *ngb = NULL;
  size_t ngb_len = 0;
  NgbStatus st = ngb_pack_elf_nodes(elf, elf_len, NGB_ARCH_X86_64_LINUX_ELF,
                                    PRINT_42_NODES, 4, &ngb, &ngb_len);
  if (st != NGB_OK) {
    fprintf(stderr, "print-42-fixture: %s\n", ngb_status_str(st));
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(ngb, ngb_len, hex);
  if (print_hash)
    printf("%s\n", hex);

  if (print_ms) {
    struct timespec t1;
    clock_gettime(CLOCK_MONOTONIC, &t1);
    long ms = (long)(t1.tv_sec - t0.tv_sec) * 1000L +
              (long)(t1.tv_nsec - t0.tv_nsec) / 1000000L;
    printf("%ld\n", ms);
  }

  if (write_fixtures) {
    const char *root = getenv("NANOGRAPH_ROOT");
    char dir[1024];
    if (root)
      snprintf(dir, sizeof(dir), "%s/fixtures", root);
    else
      snprintf(dir, sizeof(dir), "fixtures");

    char path[1200];
    snprintf(path, sizeof(path), "%s/print_42_elf.bin", dir);
    if (write_bytes(path, elf, elf_len) != 0)
      return 1;
    snprintf(path, sizeof(path), "%s/print_42.ngb", dir);
    if (write_bytes(path, ngb, ngb_len) != 0)
      return 1;
    snprintf(path, sizeof(path), "%s/print_42.ngb.hex", dir);
    if (write_hex(path, ngb, ngb_len) != 0)
      return 1;
    fprintf(stderr, "wrote %s/ graph_root_hash=%s\n", dir, hex);
  }

  free(ngb);
  return 0;
}
