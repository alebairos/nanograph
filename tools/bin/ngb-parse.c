#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void emit_json_ok(const char *hash) {
  printf("{\"ok\":true,\"graph_root_hash\":\"%s\"}\n", hash);
}

static void emit_json_err(NgbStatus st) {
  const char *msg = ngb_status_str(st);
  const char *inv = msg;
  if (strncmp(msg, "I", 1) == 0) {
    printf("{\"ok\":false,\"invariant\":\"%s\",\"message\":\"%s\"}\n", msg, msg);
  } else {
    printf("{\"ok\":false,\"invariant\":\"%s\",\"message\":\"%s\"}\n", inv, msg);
  }
}

int main(int argc, char **argv) {
  int json = 0;
  const char *path = NULL;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--json") == 0)
      json = 1;
    else if (!path)
      path = argv[i];
    else {
      fprintf(stderr, "usage: %s [--json] <file.ngb>\n", argv[0]);
      return 2;
    }
  }
  if (!path) {
    fprintf(stderr, "usage: %s [--json] <file.ngb>\n", argv[0]);
    return 2;
  }

  FILE *f = fopen(path, "rb");
  if (!f) {
    if (json) {
      printf("{\"ok\":false,\"invariant\":\"io\",\"message\":\"open failed\"}\n");
      return 1;
    }
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
    if (json) {
      emit_json_err(st);
    } else {
      fprintf(stderr, "ngb-parse: %s\n", ngb_status_str(st));
    }
    free(buf);
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(buf, (size_t)sz, hex);
  if (json)
    emit_json_ok(hex);
  else
    printf("ok graph_root_hash=%s\n", hex);
  free(buf);
  return 0;
}
