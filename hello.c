
#ifndef NOPRINT
#include <stdio.h>
#endif

#include <machine/patmos.h>

const char FOO[] = "Hello world.";
volatile int count = 12;
volatile int output;

int main(int argc, char **argv) {
  int i;

  _Pragma("loopbound min 0 max 12")
  for (i = 0; i < count; ++i) {

#ifndef NOPRINT
    putchar(FOO[i % sizeof(FOO)]);
#endif

    output = FOO[i % sizeof(FOO)];
  }

#ifndef NOPRINT
  putchar('\n');
#endif

  return 0;
}
