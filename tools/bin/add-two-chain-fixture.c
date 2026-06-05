#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PATCH1_DELTA_OFF 127
#define PATCH2_DELTA_OFF 121
#define PATCH1_ID 1
#define PATCH2_ID 2
#define PATCH_TS 1700000000ULL

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

static NgbStatus apply_pair(uint8_t **buf, size_t *len, uint32_t off,
                            const uint8_t pair[2], uint64_t patch_id) {
  static const uint8_t delta[] = {0x01, 0x02};
  (void)pair;
  NgbPatchInput patch = {
      .patch_id = patch_id,
      .delta_off = off,
      .delta_len = 2,
      .delta = delta,
      .timestamp = PATCH_TS,
  };
  uint8_t *next = NULL;
  size_t next_len = 0;
  NgbStatus st = ngb_apply_patch(*buf, *len, &patch, &next, &next_len);
  free(*buf);
  if (st != NGB_OK)
    return st;
  *buf = next;
  *len = next_len;
  return NGB_OK;
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
    snprintf(genesis_path, sizeof(genesis_path), "%s/fixtures/add_two.ngb", root);
  else
    snprintf(genesis_path, sizeof(genesis_path), "fixtures/add_two.ngb");

  uint8_t *buf = NULL;
  size_t len = 0;
  if (read_bytes(genesis_path, &buf, &len) != 0) {
    fprintf(stderr, "add-two-chain-fixture: read failed\n");
    return 1;
  }

  NgbStatus st = apply_pair(&buf, &len, PATCH1_DELTA_OFF, (const uint8_t[]){0x01, 0x02},
                            PATCH1_ID);
  if (st != NGB_OK) {
    fprintf(stderr, "add-two-chain-fixture: patch1 %s\n", ngb_status_str(st));
    return 1;
  }
  st = apply_pair(&buf, &len, PATCH2_DELTA_OFF, (const uint8_t[]){0x01, 0x02}, PATCH2_ID);
  if (st != NGB_OK) {
    fprintf(stderr, "add-two-chain-fixture: patch2 %s\n", ngb_status_str(st));
    free(buf);
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(buf, len, hex);
  if (print_hash)
    printf("%s\n", hex);

  if (write_fixtures) {
    char dir[1024];
    if (root)
      snprintf(dir, sizeof(dir), "%s/fixtures", root);
    else
      snprintf(dir, sizeof(dir), "fixtures");

    char path[1200];
    snprintf(path, sizeof(path), "%s/add_two_chain.ngb", dir);
    if (write_bytes(path, buf, len) != 0) {
      free(buf);
      return 1;
    }
    fprintf(stderr, "wrote %s graph_root_hash=%s\n", path, hex);
  }

  free(buf);
  return 0;
}
