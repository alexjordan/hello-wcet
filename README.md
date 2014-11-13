hello-wcet
==========

A Patmos helloworld example including steps for WCET analysis.

The main steps are covered by the Makefile as well.

Prerequisite: We assume to have the Patmos tools (patmos-clang, pasim, platin)
installed  in your PATH.

Compile and link the application:

```bash
patmos-clang  -o hello.elf -Xllc hello.c
```

```bash
pasim --cpuid 20 hello.print.elf
```


For WCET analysis, we compile the application again, this time without it
printing any output (we are not interested in analyzing the stdio functions)
and export information from the compiler to a PML file:
```bash
patmos-clang -DNOPRINT -o hello.noprint.elf -Xllc -mserialize=hello.noprint.pml hello.c
```


