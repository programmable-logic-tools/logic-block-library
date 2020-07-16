
#
# This Makefile executes the testbench contained in this folder
#


SRCS = $(wildcard testbench*.v)

IVFLAGS += -I../../counter/
IVFLAGS += -I../../
IVFLAGS += -I../


all: simulate
	../../testbenches/gtkw_mangler.py $(WAVEPROJECTS)

include ../../testbenches/testbench.mk

clean: clean-testbench
