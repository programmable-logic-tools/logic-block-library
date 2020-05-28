
#
# Here we define settings and targets
# common to all testbenches
#

TESTBENCHES = $(SRCS:.v=.vvp)
WAVEFILES = $(TESTBENCHES:.vvp=.lx2)
WAVEPROJECTS = $(WAVEFILES:.lx2=.gtkw)


simulate: $(WAVEFILES)

%.vvp: %.v
	iverilog $(IVFLAGS) -s test -o $@ $<

%.lx2: %.vvp
	vvp $^ -lxt2
	mv dump.lx2 $(^:.vvp=.lx2)

# Before the results can be shown, they must be generated.
show: simulate $(WAVEPROJECTS)

%.gtkw: %.lx2
	gtkwave $@ &

clean-testbench:
	rm -f $(WAVEFILES) $(TESTBENCHES)
