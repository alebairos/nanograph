#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Reference evaluator for the conformance floor (G9).
 * Computes the expected consequence from a ConfSpec.
 * Reads only the spec, never the .ngb or ELF. That independence is the point:
 * the expected value is computed from intent, not looked up from the bytes. */

enum { OP_NONE, OP_ADD, OP_SUB, OP_MUL };

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s <spec>\n", argv[0]);
    return 2;
  }
  FILE *f = fopen(argv[1], "r");
  if (!f) {
    fprintf(stderr, "conf-eval: cannot open %s\n", argv[1]);
    return 2;
  }

  int op = OP_NONE;
  long a = 0, b = 0;
  int have_a = 0, have_b = 0, have_yield = 0;
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

  if (op == OP_NONE || !have_a || !have_b || !have_yield) {
    fprintf(stderr, "conf-eval: spec missing op/a/b/yield\n");
    return 3;
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
