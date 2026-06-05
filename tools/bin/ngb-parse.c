#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s <file.ngb>\n", argv[0]);
    return 2;
  }
  FILE *f = fopen(argv[1], "rb");
  if (!f) {
    fprintf(stderr, "ngb-parse: open failed\n");
    return 1;
  }
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  rewind(f);
  if (sz < 0) {
    fclose(f);
    return 1;
  }
  uint8_t *buf = malloc((size_t)sz);
  if (!buf) {
    fclose(f);
    return 1;
  }
  if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
    free(buf);
    fclose(f);
    return 1;
  }
  fclose(f);
  NgbStatus st = ngb_parse_validate(buf, (size_t)sz);
  if (st != NGB_OK) {
    fprintf(stderr, "ngb-parse: %s\n", ngb_status_str(st));
    free(buf);
    return 1;
  }
  char hex[65];
  ngb_root_hash_hex(buf, (size_t)sz, hex);
  printf("ok graph_root_hash=%s\n", hex);
  free(buf);
  return 0;
}
