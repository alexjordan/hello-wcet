CLANG=patmos-clang
PASIM=pasim
PLATIN=platin
A3=a3patmos

PLATINOPTS=--stats --verbose
RUN_WCA=--enable-wca --disable-ait
RUN_AIT=--a3-command $(A3)
TMPDIR=platin.tmp

# no data cache modeling in Platin:
# make global memory accesses (gtime) immediate in simulator
SIMOPTS=--gtime 0

CYCLE_CHECK=ruby -rsyck -e 'c = File.open(ARGV[0]){|yf|Syck::parse(yf)}.select("/timing/*/cycles")[0].value; (print("Unexpected WCET: ",c,"\n"); exit 1) unless (200..700).include? c.to_i'

.PHONY: all run run-print run-noprint clean check
.PRECIOUS: %.pml hello%.elf

all: hello.fail.wca hello.wca

# build program and serialize program information in a PML file
hello%.elf: hello.c
	$(CLANG) $(CFLAGS) -o $@ -Xllc -mserialize=$(basename $@).pml hello.c

# [.pml is emitted when building the .elf above, dummy rule satisfies make.]
%.pml: %.elf
	@

# perform Platin WCET analysis not supplying loop bounds by the user:
# results in an unbounded solution.
# [CFLAGS is set as a target-specific make variable and used by clang]
# [$(word ...) splits and selects the 2nd word from the prerequisites]
hello.fail.wca: CFLAGS+=-DNOPRINT
hello.fail.wca: hello.noprint.pml hello.noprint.elf
	$(PLATIN) wcet $(RUN_WCA) $(PLATINOPTS) -i $< --binary $(word 2,$^) -o $@

# perform Platin WCET given a loop bound in bounds.pml:
# timing results are stored in YAML format in the .wca file
hello.wca: CFLAGS+=-DNOPRINT
hello.wca: hello.noprint.pml bounds.pml hello.noprint.elf
	$(PLATIN) wcet $(RUN_WCA) $(PLATINOPTS) -i $< -i $(word 2,$^) --binary $(word 3,$^) -o $@

hello.ait.wca: CFLAGS+=-DNOPRINT
hello.ait.wca: hello.noprint.pml bounds.pml hello.noprint.elf $(TMPDIR)/.dir
	$(PLATIN) wcet $(RUN_AIT) $(PLATINOPTS) -i $< -i $(word 2,$^) --binary $(word 3,$^) -o $@ --outdir $(TMPDIR)

$(TMPDIR)/.dir:
	mkdir -p $(TMPDIR)
	touch $@

# the CPU id determines the iteration count of the for loop: 20 iterations
# [this is an internal rule used by 'make run' and 'make run-trace'
run.%: hello.%.elf
	$(PASIM) $(SIMOPTS) --cpuid 20 $<

# run a version with I/O in the simulator
run: run.print

# run an I/O-less version with call tracing
run-trace: SIMOPTS+=--debug --debug-fmt calls
run-trace: run.noprint

check: hello.wca hello.ait.wca
	$(CYCLE_CHECK) hello.wca
	$(CYCLE_CHECK) hello.ait.wca

clean:
	rm -rf hello*.pml *.elf *.wca $(TMPDIR)


