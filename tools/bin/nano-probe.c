#include "../probe/audit_log.h"
#include "../probe/diff.h"
#include "../probe/disassemble.h"

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

static int cmd_audit_log(const char *path) {
  uint8_t *buf = NULL;
  size_t len = 0;
  if (read_file(path, &buf, &len) != 0) {
    fprintf(stderr, "nano-probe: open failed\n");
    return 1;
  }
  NgbStatus st = ngb_probe_audit_log(buf, len, stdout);
  free(buf);
  if (st != NGB_OK) {
    fprintf(stderr, "nano-probe: %s\n", ngb_status_str(st));
    return 1;
  }
  return 0;
}

static int cmd_disassemble(const char *path) {
  uint8_t *buf = NULL;
  size_t len = 0;
  if (read_file(path, &buf, &len) != 0) {
    fprintf(stderr, "nano-probe: open failed\n");
    return 1;
  }
  NgbStatus st = ngb_probe_disassemble(buf, len, stdout);
  free(buf);
  if (st != NGB_OK) {
    fprintf(stderr, "nano-probe: %s\n", ngb_status_str(st));
    return 1;
  }
  return 0;
}

static int cmd_diff(const char *left, const char *right) {
  uint8_t *lbuf = NULL;
  uint8_t *rbuf = NULL;
  size_t llen = 0;
  size_t rlen = 0;
  if (read_file(left, &lbuf, &llen) != 0 || read_file(right, &rbuf, &rlen) != 0) {
    fprintf(stderr, "nano-probe: open failed\n");
    free(lbuf);
    free(rbuf);
    return 1;
  }
  NgbStatus st = ngb_probe_diff(lbuf, llen, rbuf, rlen, stdout);
  free(lbuf);
  free(rbuf);
  if (st != NGB_OK) {
    fprintf(stderr, "nano-probe: %s\n", ngb_status_str(st));
    return 1;
  }
  return 0;
}

int main(int argc, char **argv) {
  if (argc == 3 && strcmp(argv[1], "audit-log") == 0)
    return cmd_audit_log(argv[2]);
  if (argc == 3 && strcmp(argv[1], "disassemble") == 0)
    return cmd_disassemble(argv[2]);
  if (argc == 4 && strcmp(argv[1], "diff") == 0)
    return cmd_diff(argv[2], argv[3]);
  fprintf(stderr, "usage: %s audit-log <file.ngb>\n", argv[0]);
  fprintf(stderr, "       %s disassemble <file.ngb>\n", argv[0]);
  fprintf(stderr, "       %s diff <left.ngb> <right.ngb>\n", argv[0]);
  return 2;
}
