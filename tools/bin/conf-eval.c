#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Reference evaluator for the conformance floor (G9, G17, G21).
 * Computes the expected consequence from a ConfSpec.
 * Reads only the spec, never the .ngb or ELF. That independence is the point:
 * the expected value is computed from intent, not looked up from the bytes. */

enum { OP_NONE, OP_ADD, OP_SUB, OP_MUL, OP_ECA, OP_GCD, OP_BSWAP, OP_BITREV };

enum { INPUT_NONE, INPUT_ARGV };

static long euclid_gcd(long x, long y) {
  if (x < 0)
    x = -x;
  if (y < 0)
    y = -y;
  while (y != 0) {
    long t = y;
    y = x % y;
    x = t;
  }
  return x;
}

#define ECA_MAX 512

enum { INIT_CENTER, INIT_RIGHT };

static int render_eca(int rule, int width, int gens, int init) {
  unsigned char cur[ECA_MAX], nxt[ECA_MAX];
  memset(cur, 0, sizeof cur);
  cur[init == INIT_RIGHT ? width - 1 : width / 2] = 1;

  for (int g = 0; g < gens; g++) {
    for (int i = 0; i < width; i++)
      putchar(cur[i] ? '#' : '.');
    putchar('\n');

    for (int i = 0; i < width; i++) {
      int l = i > 0 ? cur[i - 1] : 0;
      int c = cur[i];
      int r = i < width - 1 ? cur[i + 1] : 0;
      int idx = (l << 2) | (c << 1) | r;
      nxt[i] = (rule >> idx) & 1;
    }
    memcpy(cur, nxt, (size_t)width);
  }
  return 0;
}

int main(int argc, char **argv) {
  if (argc < 2 || argc > 4) {
    fprintf(stderr, "usage: %s <spec> [<x> | <a> <b>]\n", argv[0]);
    return 2;
  }
  FILE *f = fopen(argv[1], "r");
  if (!f) {
    fprintf(stderr, "conf-eval: cannot open %s\n", argv[1]);
    return 2;
  }

  int op = OP_NONE;
  int input_mode = INPUT_NONE;
  long a = 0, b = 0;
  long rule = -1, width = -1, gens = -1;
  int init = INIT_CENTER;
  int have_a = 0, have_b = 0, have_yield = 0, have_init = 0, have_input = 0;
  char line[256];

  while (fgets(line, sizeof line, f)) {
    char *eq = strchr(line, '=');
    if (line[0] == '#' || line[0] == '\n' || !eq)
      continue;
    *eq = '\0';
    char *key = line;
    char *val = eq + 1;
    val[strcspn(val, "\r\n")] = '\0';

    if (strcmp(key, "op") == 0) {
      if (strcmp(val, "add") == 0)
        op = OP_ADD;
      else if (strcmp(val, "sub") == 0)
        op = OP_SUB;
      else if (strcmp(val, "mul") == 0)
        op = OP_MUL;
      else if (strcmp(val, "eca") == 0)
        op = OP_ECA;
      else if (strcmp(val, "gcd") == 0)
        op = OP_GCD;
      else if (strcmp(val, "bswap") == 0)
        op = OP_BSWAP;
      else if (strcmp(val, "bitrev") == 0)
        op = OP_BITREV;
      else {
        fprintf(stderr, "conf-eval: unknown op %s\n", val);
        fclose(f);
        return 3;
      }
    } else if (strcmp(key, "a") == 0) {
      a = strtol(val, NULL, 10);
      have_a = 1;
    } else if (strcmp(key, "b") == 0) {
      b = strtol(val, NULL, 10);
      have_b = 1;
    } else if (strcmp(key, "rule") == 0) {
      rule = strtol(val, NULL, 10);
    } else if (strcmp(key, "width") == 0) {
      width = strtol(val, NULL, 10);
    } else if (strcmp(key, "gens") == 0) {
      gens = strtol(val, NULL, 10);
    } else if (strcmp(key, "init") == 0) {
      if (strcmp(val, "center") == 0)
        init = INIT_CENTER;
      else if (strcmp(val, "right") == 0)
        init = INIT_RIGHT;
      else {
        fprintf(stderr, "conf-eval: unsupported init %s (v0: center, right)\n", val);
        fclose(f);
        return 3;
      }
      have_init = 1;
    } else if (strcmp(key, "input") == 0) {
      if (strcmp(val, "argv") == 0) {
        input_mode = INPUT_ARGV;
        have_input = 1;
      } else {
        fprintf(stderr, "conf-eval: unsupported input %s (v0: argv)\n", val);
        fclose(f);
        return 3;
      }
    } else if (strcmp(key, "yield") == 0) {
      if (strcmp(val, "exit") != 0 && strcmp(val, "stdout") != 0) {
        fprintf(stderr, "conf-eval: unsupported yield %s (v0: exit, stdout)\n", val);
        fclose(f);
        return 3;
      }
      have_yield = 1;
    }
  }
  fclose(f);

  if (op == OP_GCD) {
    if (input_mode != INPUT_ARGV || !have_input || !have_yield || argc != 4) {
      fprintf(stderr, "conf-eval: gcd spec needs input=argv yield=stdout and args <a> <b>\n");
      return 3;
    }
    a = strtol(argv[2], NULL, 10);
    b = strtol(argv[3], NULL, 10);
    printf("%ld\n", euclid_gcd(a, b));
    return 0;
  }

  if (op == OP_BSWAP) {
    if (input_mode != INPUT_ARGV || !have_input || !have_yield || argc != 3) {
      fprintf(stderr, "conf-eval: bswap spec needs input=argv yield=stdout and arg <x>\n");
      return 3;
    }
    unsigned long x = strtoul(argv[2], NULL, 10) & 0xFFFFFFFFUL;
    unsigned long s = ((x & 0x000000FFUL) << 24) | ((x & 0x0000FF00UL) << 8) |
                      ((x & 0x00FF0000UL) >> 8) | ((x & 0xFF000000UL) >> 24);
    printf("%lu\n", s);
    return 0;
  }

  if (op == OP_BITREV) {
    if (input_mode != INPUT_ARGV || !have_input || !have_yield || argc != 3) {
      fprintf(stderr, "conf-eval: bitrev spec needs input=argv yield=stdout and arg <x>\n");
      return 3;
    }
    unsigned long x = strtoul(argv[2], NULL, 10) & 0xFFFFFFFFUL;
    unsigned long r = 0;
    for (int i = 0; i < 32; i++)
      r = (r << 1) | ((x >> i) & 1UL);
    printf("%lu\n", r & 0xFFFFFFFFUL);
    return 0;
  }

  if (op == OP_ECA) {
    if (argc != 2) {
      fprintf(stderr, "conf-eval: eca spec takes only <spec>\n");
      return 2;
    }
    if (rule < 0 || rule > 255 || width < 1 || width > ECA_MAX ||
        gens < 1 || gens > ECA_MAX || !have_init || !have_yield) {
      fprintf(stderr, "conf-eval: eca spec needs rule 0-255, width/gens 1-%d, init=center|right, yield\n", ECA_MAX);
      return 3;
    }
    return render_eca((int)rule, (int)width, (int)gens, init);
  }

  if (op == OP_NONE || !have_a || !have_b || !have_yield) {
    fprintf(stderr, "conf-eval: spec missing op/a/b/yield\n");
    return 3;
  }

  if (argc != 2) {
    fprintf(stderr, "conf-eval: fixed-operand spec takes only <spec>\n");
    return 2;
  }

  long r;
  switch (op) {
  case OP_ADD:
    r = a + b;
    break;
  case OP_SUB:
    r = a - b;
    break;
  case OP_MUL:
    r = a * b;
    break;
  default:
    return 3;
  }

  printf("%ld\n", r);
  return 0;
}
