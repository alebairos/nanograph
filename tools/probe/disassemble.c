#include "disassemble.h"

#include <inttypes.h>
#include <stdio.h>
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

static void hex_bytes(FILE *out, const uint8_t *b, size_t n) {
  static const char *d = "0123456789abcdef";
  for (size_t i = 0; i < n; i++) {
    if (i > 0)
      fputc(' ', out);
    fputc(d[(b[i] >> 4) & 0xf], out);
    fputc(d[b[i] & 0xf], out);
  }
}

static int elf_code_region(const uint8_t *image, uint32_t image_len,
                           uint32_t *code_off, uint32_t *code_len) {
  if (image_len < 120 || image[0] != 0x7f || image[1] != 'E' || image[2] != 'L' ||
      image[3] != 'F')
    return 0;
  uint64_t off = u64le(image + 72);
  uint64_t filesz = u64le(image + 96);
  if (off >= image_len || filesz == 0 || off + filesz > image_len)
    return 0;
  *code_off = (uint32_t)off;
  *code_len = (uint32_t)filesz;
  return 1;
}

static size_t disasm_one(const uint8_t *p, size_t avail, FILE *out) {
  if (avail == 0)
    return 0;
  if (p[0] == 0xB8 && avail >= 5) {
    fprintf(out, "  mov eax, %u\n", u32le(p + 1));
    return 5;
  }
  if (p[0] == 0x83 && avail >= 3 && p[1] == 0xC0) {
    fprintf(out, "  add eax, %u\n", (unsigned)p[2]);
    return 3;
  }
  if (p[0] == 0x89 && avail >= 2 && p[1] == 0xC7) {
    fputs("  mov edi, eax\n", out);
    return 2;
  }
  if (p[0] == 0x48 && avail >= 3 && p[1] == 0x31 && p[2] == 0xFF) {
    fputs("  xor rdi, rdi\n", out);
    return 3;
  }
  if (p[0] == 0x0F && avail >= 2 && p[1] == 0x05) {
    fputs("  syscall\n", out);
    return 2;
  }
  fprintf(out, "  db 0x%02x\n", (unsigned)p[0]);
  return 1;
}

static void disasm_range(FILE *out, const uint8_t *image, uint32_t off,
                         uint32_t nlen) {
  uint32_t pos = 0;
  while (pos < nlen) {
    size_t step = disasm_one(image + off + pos, nlen - pos, out);
    if (step == 0)
      break;
    pos += (uint32_t)step;
  }
}

static void node_image_slice(uint32_t image_len, uint32_t code_off, uint32_t code_len,
                             uint32_t node_count, const uint8_t *n, uint32_t *img_off,
                             uint32_t *img_len) {
  uint32_t off = u32le(n + 8);
  uint32_t nlen = u32le(n + 12);

  if (node_count == 1 && off == 0 && nlen == image_len) {
    *img_off = code_off;
    *img_len = code_len;
    return;
  }
  if (off + nlen <= code_len) {
    *img_off = code_off + off;
    *img_len = nlen;
    return;
  }
  if (off >= code_off && off + nlen <= image_len) {
    *img_off = off;
    *img_len = nlen;
    return;
  }
  *img_off = off;
  *img_len = nlen;
}

NgbStatus ngb_probe_disassemble(const uint8_t *data, size_t len, FILE *out) {
  NgbStatus st = ngb_parse_validate(data, len);
  if (st != NGB_OK)
    return st;

  uint16_t arch_id = (uint16_t)(data[6] | (data[7] << 8));
  if (arch_id != NGB_ARCH_X86_64_LINUX_ELF)
    return NGB_ERR_IO;

  uint32_t image_off = u32le(data + 12);
  uint32_t image_len = u32le(data + 16);
  uint32_t node_off = u32le(data + 20);
  uint32_t node_count = u32le(data + 24);

  const uint8_t *image = data + image_off;

  uint32_t code_off = 0;
  uint32_t code_len = 0;
  if (!elf_code_region(image, image_len, &code_off, &code_len))
    return NGB_ERR_IO;

  char root[65];
  ngb_root_hash_hex(data, len, root);

  fprintf(out, "format=nano-probe-disassemble-v0\n");
  fprintf(out, "graph_root_hash=%s\n", root);
  fprintf(out, "arch_id=%u\n", (unsigned)arch_id);
  fprintf(out, "code_offset=%u\n", code_off);
  fprintf(out, "code_length=%u\n", code_len);

  for (uint32_t i = 0; i < node_count; i++) {
    const uint8_t *n = data + node_off + i * NGB_NODE_SIZE;
    uint64_t nid = u64le(n);
    uint32_t slice_off = 0;
    uint32_t slice_len = 0;
    node_image_slice(image_len, code_off, code_len, node_count, n, &slice_off,
                     &slice_len);
    if (slice_off + slice_len > image_len)
      return NGB_ERR_I3_NODE_RANGE;

    fprintf(out, "instr #instr_%" PRIx64 " image_offset=%u length=%u bytes=",
            nid, slice_off, slice_len);
    hex_bytes(out, image + slice_off, slice_len);
    fputc('\n', out);
    disasm_range(out, image, slice_off, slice_len);
  }

  return NGB_OK;
}
