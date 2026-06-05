#include "../probe/audit_log.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int cmd_audit_log(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f) {
    fprintf(stderr, "nano-probe: open failed\n");
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

  NgbStatus st = ngb_probe_audit_log(buf, (size_t)sz, stdout);
  free(buf);
  if (st != NGB_OK) {
    fprintf(stderr, "nano-probe: %s\n", ngb_status_str(st));
    return 1;
  }
  return 0;
}

int main(int argc, char **argv) {
  if (argc != 3 || strcmp(argv[1], "audit-log") != 0) {
    fprintf(stderr, "usage: %s audit-log <file.ngb>\n", argv[0]);
    return 2;
  }
  return cmd_audit_log(argv[2]);
}
