
#
# Here we define settings and targets
# common to all testbenches
#

ifndef LIB_ROOT
LIB_ROOT = ..
endif

IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
GTKW_MANGLER = $(LIB_ROOT)/tools/gtkw_mangler.py

TESTBENCHES = $(SRCS:.v=.vvp)
WAVEFILES = $(TESTBENCHES:.vvp=.lx2)
WAVEPROJECTS = $(WAVEFILES:.lx2=.gtkw)


simulate: $(WAVEFILES)

.PRECIOUS: %.gtkw %.vvp %.lx2 %.vcd

%.vvp: %.v
	$(IVERILOG) $(IVFLAGS) -s test -o $@ $<

%.lx2: %.vvp
	$(VVP) $^ -lxt2
	mv dump.lx2 $(^:.vvp=.lx2)

%.vcd: %.vvp
	$(VVP) $^ -vcd
	mv dump.vcd $(^:.vvp=.vcd)

# Before the results can be shown, they must be generated.
.PHONY: show
show: simulate $(WAVEPROJECTS)

.PHONY: %.gtkw
%.gtkw: %.lx2
	touch $@
	$(GTKWAVE) $@
	$(GTKW_MANGLER) $(WAVEPROJECTS)

.PHONY: gtkw_mangler
gtkw_mangler:
	$(GTKW_MANGLER) $(WAVEPROJECTS)

clean-testbench:
	rm -f $(WAVEFILES) $(TESTBENCHES)
