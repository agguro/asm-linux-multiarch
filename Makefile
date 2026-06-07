# ==============================================================================
# ASM-LINUX-MULTIARCH: ROOT MANAGEMENT FRAMEWORK
# ==============================================================================

# Find any directory containing a Makefile between 2 and 3 levels deep.
# This catches direct branches (./cuda) and nested subprojects (./projects/complex-quadsolver)
# Set maxdepth to 5 to discover deeply structured multiarch architecture tools within submodules
SUBDIRS      := $(patsubst %/,%,$(dir $(shell find . -mindepth 2 -maxdepth 5 -name Makefile)))

# Set the absolute root based on PWD
ifndef PARENTROOT
    export PARENTROOT := $(CURDIR)/
endif

GLOBAL_BUILD := $(PARENTROOT)build
GLOBAL_BIN   := $(PARENTROOT)bin

all: debug

# DIRECT EXECUTION LOOP
debug release clean test: directories
	@for dir in $(SUBDIRS); do \
		echo "=============================================================================="; \
		echo "Entering Target Directory: $$dir -> Target: $@"; \
		echo "=============================================================================="; \
		$(MAKE) -C $$dir $@ || exit 1; \
	done

directories:
	@mkdir -p $(GLOBAL_BUILD)
	@mkdir -p $(GLOBAL_BIN)

deep_clean:
	@echo "Removing centralized build and binary directories..."
	rm -rf $(GLOBAL_BUILD) $(GLOBAL_BIN)

.PHONY: all debug release clean test directories deep_clean
