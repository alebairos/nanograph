#include "../ngb/ngb.h"

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

static int parse_hex_byte(const char *s, uint8_t *out) {
  unsigned int v = 0;
  if (sscanf(s, "%2x", &v) != 1 || v > 255)
    return -1;
  *out = (uint8_t)v;
  return 0;
}

int main(int argc, char **argv) {
  uint32_t delta_off = 0;
  uint64_t patch_id = 1;
  uint64_t timestamp = 1700000000ULL;
  const char *in_path = NULL;
  const char *out_path = NULL;
  uint8_t delta[256];
  size_t delta_len = 0;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--off") == 0 && i + 1 < argc) {
      delta_off = (uint32_t)strtoul(argv[++i], NULL, 10);
    } else if (strcmp(argv[i], "--pair") == 0 && i + 1 < argc) {
      char *pair = argv[++i];
      char *colon = strchr(pair, ':');
      if (!colon || delta_len + 2 > sizeof(delta)) {
        fprintf(stderr, "ngb-patch: bad --pair (want old:new hex)\n");
        return 2;
      }
      *colon = '\0';
      if (parse_hex_byte(pair, &delta[delta_len]) != 0 ||
          parse_hex_byte(colon + 1, &delta[delta_len + 1]) != 0) {
        fprintf(stderr, "ngb-patch: bad hex in --pair\n");
        return 2;
      }
      delta_len += 2;
    } else if (strcmp(argv[i], "--patch-id") == 0 && i + 1 < argc) {
      patch_id = strtoull(argv[++i], NULL, 10);
    } else if (strcmp(argv[i], "--timestamp") == 0 && i + 1 < argc) {
      timestamp = strtoull(argv[++i], NULL, 10);
    } else if (!in_path) {
      in_path = argv[i];
    } else if (!out_path) {
      out_path = argv[i];
    } else {
      fprintf(stderr, "ngb-patch: unexpected arg %s\n", argv[i]);
      return 2;
    }
  }

  if (!in_path || !out_path || delta_len == 0) {
    fprintf(stderr,
            "usage: %s <in.ngb> <out.ngb> --off N --pair old:new [--pair ...] "
            "[--patch-id N] [--timestamp N]\n",
            argv[0]);
    return 2;
  }

  uint8_t *base = NULL;
  size_t base_len = 0;
  if (read_file(in_path, &base, &base_len) != 0) {
    fprintf(stderr, "ngb-patch: read failed\n");
    return 1;
  }

  NgbPatchInput patch = {
      .patch_id = patch_id,
      .delta_off = delta_off,
      .delta_len = (uint32_t)delta_len,
      .delta = delta,
      .timestamp = timestamp,
  };

  uint8_t *out = NULL;
  size_t out_len = 0;
  NgbStatus st = ngb_apply_patch(base, base_len, &patch, &out, &out_len);
  free(base);
  if (st != NGB_OK) {
    fprintf(stderr, "ngb-patch: %s\n", ngb_status_str(st));
    return 1;
  }

  if (write_file(out_path, out, out_len) != 0) {
    free(out);
    fprintf(stderr, "ngb-patch: write failed\n");
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(out, out_len, hex);
  printf("ok graph_root_hash=%s\n", hex);
  free(out);
  return 0;
}
