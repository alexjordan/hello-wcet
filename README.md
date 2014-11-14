# hello-wcet

A Patmos helloworld example including steps for WCET analysis.


## Prerequisites

We assume to have the Patmos tools (patmos-clang, pasim, platin)
installed in our PATH.

All major steps below can be conveniently reproduced via the Makefile.

## Compiling and Running

We start by compiling and linking the helloworld program like this:

```bash
patmos-clang -o hello.elf hello.c
```

Executing the binary using the Patmos simulator `pasim` does what we expect it
to do:

```bash
pasim hello.elf   # (make run)
Hello world.
```

To make helloworld interesting for WCET analysis, the number of characters we
output from the "Hello world." string depends on a (loop) count defined here:

```c
volatile int count = 12;
```

We can change the loop count and rerun pasim to see the effect immediately.

## WCET Analysis

In order to perform WCET analysis, we compile the application again, this time
without printing characters to output, as we are not interested in analyzing
the stdio functions. (Instead characters are written to an `output` register.)
Defining `NOPRINT` will exclude the stdio functions; at the same time we export
meta-information from the compiler to a PML file:

```bash
patmos-clang -DNOPRINT -o hello.noprint.elf -mserialize=hello.noprint.pml hello.c   # (make hello.noprint.elf)
```

Running the noprint version of helloworld will no longer give us any output on
the console, but we can still see what is happening by e.g. tracing function
calls in the simulator:

```bash
pasim --gtime 0 --debug --debug-fmt calls hello.noprint.elf
<...>
00020350      4786 call from <_start> to <main> args: r3 = 00000000, r4 = 00000000, r5 = f0000100, r6 = 00000040, r7 = 00000040, r8 = 0002f100
000207c0      5015 return from <main> to <_start> retval: r1 = 00000000, r2 = 4ec4ec4f
<...>
```

We can now perform WCET analysis (of function main) using platin's internal
analysis (`--enable-wca`); results will be stored in the file `hello.wca`:

```bash
platin wcet --enable-wca --disable-ait --stats --verbose -i hello.noprint.pml --binary hello.noprint.elf -o hello.wca   # (make hello.wca)
<...>
Cycles: 229
```

Success! We can see that the cycles computed as the WCET bound for our
helloworld program matches the runtime we measured using the simulator above.

### Loop bounds

WCET analysis for our helloworld example depends on a loopbound that is provided
as a source code annotation:

```c
  _Pragma("loopbound min 0 max 12")
  for (i = 0; i < count; ++i) {
```

Changing the upper bound will directly affect the WCET bound, while removing it
and rerunning the platin analysis will result in an 'unbounded' error:

```
[platin] WARNING: LPSolve: Unbounded loops: (main)4/2
[platin] WARNING: WCA: ILP failed: LPSolver Error: UNBOUNDED (E3)

```
