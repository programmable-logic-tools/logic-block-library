
#
# This Makefile executes the testbench contained in this folder
#


SRCS = $(wildcard testbench*.v)

LIB_ROOT = ../..
IVFLAGS += -I$(LIB_ROOT)
IVFLAGS += -I..


all: simulate

include $(LIB_ROOT)/testbenches/testbench.mk

clean: clean-testbench
