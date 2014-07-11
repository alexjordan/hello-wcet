
#ifndef NOPRINT
#include <stdio.h>
#endif

#include <machine/patmos.h>

const char FOO[] = "Hello world.";
volatile int bar;

int main(int argc, char **argv) {
  int i, z;

  z = (int) get_cpuid();

  __llvm_pcmarker(0);
  for (i = 0; i < z; ++i) {
    __llvm_pcmarker(1);

#ifndef NOPRINT
    putchar(FOO[i % sizeof(FOO)]);
#endif

    bar = FOO[i % sizeof(FOO)];
  }

#ifndef NOPRINT
  putchar('\n');
#endif

  return 0;
}
