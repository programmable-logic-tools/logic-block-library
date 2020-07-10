
#
# This Makefile executes the testbench contained in this folder
#


SRCS = $(wildcard testbench*.v)

IVFLAGS += -I../../
IVFLAGS += -I../


all: simulate

include ../../testbenches/testbench.mk

clean: clean-testbench
