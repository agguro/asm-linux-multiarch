# Makefile
SUBDIRS := $(patsubst %/,%,$(dir $(shell find . -mindepth 2 -maxdepth 2 -name Makefile)))

all: debug

debug release clean test:
	@mkdir -p build
	@( for dir in $(SUBDIRS); do $(MAKE) -C $$dir $@ || exit 1; done ) 2>&1 | tee build/framework_build.log

list:
	@echo "Directe submappen vanuit Root:"
	@for dir in $(SUBDIRS); do echo " - $$dir"; done

.PHONY: all debug release clean test list
