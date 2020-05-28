
#
# This Makefile executes the testbench contained in this folder
#


SRCS = $(wildcard testbench*.v)

IVFLAGS += -I../../../
IVFLAGS += -I../../../averaging/


all: simulate

include ../../testbench.mk

clean: clean-testbench
