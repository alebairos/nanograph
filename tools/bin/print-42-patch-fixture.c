#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PRINT_42_PATCH_DELTA_OFF 152
#define PRINT_42_PATCH_ID 1
#define PRINT_42_PATCH_TS 1700000000ULL

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

static int read_bytes(const char *path, uint8_t **out, size_t *out_len) {
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

int main(int argc, char **argv) {
  int print_hash = 0;
  int write_fixtures = 1;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--print-hash") == 0)
      print_hash = 1;
    if (strcmp(argv[i], "--no-write") == 0)
      write_fixtures = 0;
  }

  const char *root = getenv("NANOGRAPH_ROOT");
  char genesis_path[1200];
  if (root)
    snprintf(genesis_path, sizeof(genesis_path), "%s/fixtures/print_42.ngb", root);
  else
    snprintf(genesis_path, sizeof(genesis_path), "fixtures/print_42.ngb");

  uint8_t *genesis = NULL;
  size_t genesis_len = 0;
  if (read_bytes(genesis_path, &genesis, &genesis_len) != 0) {
    fprintf(stderr, "print-42-patch-fixture: read failed\n");
    return 1;
  }

  static const uint8_t delta[] = {0x32, 0x33};
  NgbPatchInput patch = {
      .patch_id = PRINT_42_PATCH_ID,
      .delta_off = PRINT_42_PATCH_DELTA_OFF,
      .delta_len = 2,
      .delta = delta,
      .timestamp = PRINT_42_PATCH_TS,
  };

  uint8_t *patched = NULL;
  size_t patched_len = 0;
  NgbStatus st = ngb_apply_patch(genesis, genesis_len, &patch, &patched, &patched_len);
  free(genesis);
  if (st != NGB_OK) {
    fprintf(stderr, "print-42-patch-fixture: %s\n", ngb_status_str(st));
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(patched, patched_len, hex);
  if (print_hash)
    printf("%s\n", hex);

  if (write_fixtures) {
    char dir[1024];
    if (root)
      snprintf(dir, sizeof(dir), "%s/fixtures", root);
    else
      snprintf(dir, sizeof(dir), "fixtures");

    char path[1200];
    snprintf(path, sizeof(path), "%s/print_42_patched.ngb", dir);
    if (write_bytes(path, patched, patched_len) != 0)
      return 1;
    fprintf(stderr, "wrote %s graph_root_hash=%s\n", path, hex);
  }

  free(patched);
  return 0;
}
