#include "../ngb/ngb.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t u32le(const uint8_t *p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static uint64_t u64le(const uint8_t *p) {
  uint64_t v = 0;
  for (int i = 7; i >= 0; i--)
    v = (v << 8) | p[i];
  return v;
}

/* Structural ELF64 validator: every invariant a careful hex editor could check
   with readelf before shipping. It cannot validate code bytes, because ELF
   stores no expectation of its own contents. That gap is the format's, not the
   checker's. Returns 0 when structurally valid. */
static int elf_validate(const uint8_t *e, size_t len) {
  if (len < 64)
    return 1;
  if (!(e[0] == 0x7f && e[1] == 'E' && e[2] == 'L' && e[3] == 'F'))
    return 2;
  if (e[4] != 2)
    return 3;
  if (e[5] != 1)
    return 4;
  uint16_t e_type = (uint16_t)(e[16] | (e[17] << 8));
  if (e_type != 2 && e_type != 3)
    return 5;
  uint16_t e_machine = (uint16_t)(e[18] | (e[19] << 8));
  if (e_machine != 0x3e)
    return 6;
  uint64_t phoff = u64le(e + 32);
  uint16_t phentsize = (uint16_t)(e[54] | (e[55] << 8));
  uint16_t phnum = (uint16_t)(e[56] | (e[57] << 8));
  if (phoff + (uint64_t)phnum * phentsize > len)
    return 7;
  for (uint16_t i = 0; i < phnum; i++) {
    const uint8_t *ph = e + phoff + (size_t)i * phentsize;
    uint64_t p_offset = u64le(ph + 8);
    uint64_t p_filesz = u64le(ph + 32);
    if (p_offset + p_filesz > len)
      return 8;
  }
  return 0;
}

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
  if (!buf || fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
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
  unsigned trials = 500;
  unsigned seed = 1;
  const char *ngb_path = NULL;
  const char *elf_path = NULL;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--trials") == 0 && i + 1 < argc)
      trials = (unsigned)strtoul(argv[++i], NULL, 10);
    else if (strcmp(argv[i], "--seed") == 0 && i + 1 < argc)
      seed = (unsigned)strtoul(argv[++i], NULL, 10);
    else if (!ngb_path)
      ngb_path = argv[i];
    else if (!elf_path)
      elf_path = argv[i];
    else {
      fprintf(stderr, "usage: %s <ngb> <elf> [--trials N] [--seed S]\n", argv[0]);
      return 2;
    }
  }
  if (!ngb_path || !elf_path) {
    fprintf(stderr, "usage: %s <ngb> <elf> [--trials N] [--seed S]\n", argv[0]);
    return 2;
  }

  uint8_t *ngb = NULL, *elf = NULL;
  size_t ngb_len = 0, elf_len = 0;
  if (read_file(ngb_path, &ngb, &ngb_len) != 0)
    return fprintf(stderr, "ngb-fuzz: read %s failed\n", ngb_path), 1;
  if (read_file(elf_path, &elf, &elf_len) != 0)
    return fprintf(stderr, "ngb-fuzz: read %s failed\n", elf_path), 1;

  if (ngb_parse_validate(ngb, ngb_len) != NGB_OK)
    return fprintf(stderr, "ngb-fuzz: base ngb invalid\n"), 1;
  if (elf_validate(elf, elf_len) != 0)
    return fprintf(stderr, "ngb-fuzz: base elf invalid\n"), 1;

  uint32_t image_off = u32le(ngb + 12);
  uint32_t image_len = u32le(ngb + 16);
  if (image_len != elf_len)
    return fprintf(stderr, "ngb-fuzz: image_len %u != elf_len %zu\n", image_len, elf_len), 1;

  srand(seed);
  uint8_t *ngb_copy = malloc(ngb_len);
  uint8_t *elf_copy = malloc(elf_len);
  if (!ngb_copy || !elf_copy)
    return fprintf(stderr, "ngb-fuzz: alloc\n"), 1;

  unsigned ngb_caught = 0, elf_caught = 0;
  for (unsigned t = 0; t < trials; t++) {
    uint32_t off = (uint32_t)(rand() % image_len);
    uint8_t old = elf[off];
    uint8_t flip;
    do {
      flip = (uint8_t)(rand() & 0xff);
    } while (flip == old);

    memcpy(ngb_copy, ngb, ngb_len);
    memcpy(elf_copy, elf, elf_len);
    ngb_copy[image_off + off] = flip;
    elf_copy[off] = flip;

    if (ngb_parse_validate(ngb_copy, ngb_len) != NGB_OK)
      ngb_caught++;
    if (elf_validate(elf_copy, elf_len) != 0)
      elf_caught++;
  }

  printf("ngb-fuzz trials=%u seed=%u image_len=%u ngb_caught=%u elf_caught=%u\n",
         trials, seed, image_len, ngb_caught, elf_caught);

  free(ngb);
  free(elf);
  free(ngb_copy);
  free(elf_copy);
  return ngb_caught == trials ? 0 : 3;
}
