#include "../ngb/ngb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Pack CA ELF with nodes that exclude the rule-immediate byte at image offset
 * 4424, so single-byte patches validate (I6) like add_two_patched. */

#define CA_RULE30_PATCH_OFF 4424

static const NgbNodeSpec CA_RULE30_NODES[] = {
    {1, 0, CA_RULE30_PATCH_OFF},
    {2, CA_RULE30_PATCH_OFF + 1, 0},
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
  const char *elf_path = NULL;
  const char *ngb_name = NULL;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--print-hash") == 0)
      print_hash = 1;
    else if (strcmp(argv[i], "--no-write") == 0)
      write_fixtures = 0;
    else if (!elf_path)
      elf_path = argv[i];
    else if (!ngb_name)
      ngb_name = argv[i];
  }

  if (!elf_path || !ngb_name) {
    fprintf(stderr, "usage: %s [--print-hash] [--no-write] <elf> <out.ngb>\n",
            argv[0]);
    return 2;
  }

  uint8_t *elf = NULL;
  size_t elf_len = 0;
  if (read_bytes(elf_path, &elf, &elf_len) != 0) {
    fprintf(stderr, "ca-rule30-fixture: read %s failed\n", elf_path);
    return 1;
  }

  NgbNodeSpec nodes[2];
  memcpy(nodes, CA_RULE30_NODES, sizeof nodes);
  nodes[1].length = (uint32_t)(elf_len - (CA_RULE30_PATCH_OFF + 1));

  uint8_t *ngb = NULL;
  size_t ngb_len = 0;
  NgbStatus st = ngb_pack_elf_nodes(elf, elf_len, NGB_ARCH_X86_64_LINUX_ELF, nodes,
                                    2, &ngb, &ngb_len);
  free(elf);
  if (st != NGB_OK) {
    fprintf(stderr, "ca-rule30-fixture: %s\n", ngb_status_str(st));
    return 1;
  }

  char hex[65];
  ngb_root_hash_hex(ngb, ngb_len, hex);
  if (print_hash)
    printf("%s\n", hex);

  if (write_fixtures) {
    if (write_bytes(ngb_name, ngb, ngb_len) != 0)
      return 1;
    fprintf(stderr, "wrote %s graph_root_hash=%s\n", ngb_name, hex);
  }

  free(ngb);
  return 0;
}
