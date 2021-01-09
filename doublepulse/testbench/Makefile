
#
# This Makefile executes the testbench contained in this folder
#


SRCS = $(wildcard testbench*.v)

IVFLAGS += -I../../counter/
IVFLAGS += -I../../pwm/
IVFLAGS += -I../../
IVFLAGS += -I../

GTKW_MANGLER = ../../tools/gtkw_mangler.py


all: simulate

include ../../testbenches/testbench.mk

clean: clean-testbench
