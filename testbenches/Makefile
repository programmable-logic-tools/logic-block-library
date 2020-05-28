
# A list of testbenches to run
SUBDIRS += averaging/cycled/
SUBDIRS += averaging/stimulus/
SUBDIRS += averaging/sliding/
SUBDIRS += spi_receiver/
SUBDIRS += spi_stimulus/
SUBDIRS += spi_transmitter/


all: run
test: run
tests: run
run: $(addsuffix .run,$(SUBDIRS))
$(addsuffix .run,$(SUBDIRS)):
	$(MAKE) -B -C $(basename $@) all

clean: $(addsuffix .clean,$(SUBDIRS))
$(addsuffix .clean,$(SUBDIRS)):
	$(MAKE) -B -C $(basename $@) clean
