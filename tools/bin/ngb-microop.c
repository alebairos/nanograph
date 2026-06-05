#include "../ngb/microop.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_file(const char *path, uint8_t **out, size_t *out_len) {
  FILE *f = fopen(path, "rb");
  if (!f)
    return -1;
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  rewind(f);
  if (sz < 0) {
    fclose(f);
    return -1;
  }
  uint8_t *buf = malloc((size_t)sz);
  if (!buf) {
    fclose(f);
    return -1;
  }
  if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
    free(buf);
    fclose(f);
    return -1;
  }
  fclose(f);
  *out = buf;
  *out_len = (size_t)sz;
  return 0;
}

static int write_file(const char *path, const uint8_t *data, size_t len) {
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

int main(int argc, char **argv) {
  int check_only = 0;
  int have_expect_new = 0;
  uint8_t expect_new = 0;
  uint64_t patch_id = 1;
  uint64_t timestamp = 1700000000ULL;
  const char *genesis_path = NULL;
  const char *spec_path = NULL;
  const char *out_path = NULL;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--check-only") == 0)
      check_only = 1;
    else if (strcmp(argv[i], "--expect-new") == 0 && i + 1 < argc) {
      unsigned int v = 0;
      if (sscanf(argv[++i], "%2x", &v) != 1 || v > 255) {
        fprintf(stderr, "ngb-microop: bad --expect-new hex\n");
        return 2;
      }
      expect_new = (uint8_t)v;
      have_expect_new = 1;
    } else if (strcmp(argv[i], "--patch-id") == 0 && i + 1 < argc)
      patch_id = strtoull(argv[++i], NULL, 10);
    else if (strcmp(argv[i], "--timestamp") == 0 && i + 1 < argc)
      timestamp = strtoull(argv[++i], NULL, 10);
    else if (!genesis_path)
      genesis_path = argv[i];
    else if (!spec_path)
      spec_path = argv[i];
    else if (!out_path)
      out_path = argv[i];
  }

  if (!genesis_path || !spec_path || (!check_only && !out_path)) {
    fprintf(stderr,
            "usage: %s <genesis.ngb> <microop.spec> <out.ngb> [--check-only] "
            "[--expect-new HH] [--patch-id N] [--timestamp T]\n",
            argv[0]);
    return 2;
  }

  MicroOpRodataByteWrite op;
  MicroOpStatus ms = microop_parse_rodata_byte_write(spec_path, &op);
  if (ms != MICROOP_OK) {
    printf("static=reject invariant=spec detail=%s\n", microop_status_str(ms));
    return 1;
  }

  uint8_t *genesis = NULL;
  size_t genesis_len = 0;
  if (read_file(genesis_path, &genesis, &genesis_len) != 0) {
    fprintf(stderr, "ngb-microop: read %s failed\n", genesis_path);
    return 2;
  }

  ms = microop_validate_rodata_byte_write(genesis, genesis_len, &op);
  if (ms != MICROOP_OK) {
    printf("static=reject invariant=%s detail=microop %s\n", microop_status_str(ms),
           microop_status_str(ms));
    free(genesis);
    return 1;
  }

  if (have_expect_new && op.new_byte != expect_new) {
    printf("static=reject invariant=value_mismatch detail=new %02x want %02x\n",
           op.new_byte, expect_new);
    free(genesis);
    return 1;
  }

  if (check_only) {
    printf("static=accept kind=rodata_byte_write image_off=%u new=%02x\n",
           op.image_off, op.new_byte);
    free(genesis);
    return 0;
  }

  uint8_t *patched = NULL;
  size_t patched_len = 0;
  ms = microop_apply_rodata_byte_write(genesis, genesis_len, &op, patch_id, timestamp,
                                       &patched, &patched_len);
  free(genesis);
  if (ms != MICROOP_OK) {
    printf("static=reject invariant=%s detail=apply %s\n", microop_status_str(ms),
           microop_status_str(ms));
    return 1;
  }

  if (write_file(out_path, patched, patched_len) != 0) {
    free(patched);
    fprintf(stderr, "ngb-microop: write %s failed\n", out_path);
    return 2;
  }

  char hex[65];
  ngb_root_hash_hex(patched, patched_len, hex);
  printf("static=accept kind=rodata_byte_write graph_root_hash=%s\n", hex);
  free(patched);
  return 0;
}
