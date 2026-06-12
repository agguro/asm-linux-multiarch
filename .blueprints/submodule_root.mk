# ==============================================================================
# ASM-LINUX-FRAMEWORK: SUBMODULE ROOT ORCHESTRATOR
# BPI-BLUEPRINT: .blueprints/submodule_root.mk
# ==============================================================================

ifndef LAUNCH_ROOT
    export LAUNCH_ROOT := $(abspath $(CURDIR))/
endif

SUBDIRS := kernels x86_64

all: debug

debug release clean test install:
	@for dir in $(SUBDIRS); do \
		if [ -d $$dir ] && [ -f $$dir/Makefile ]; then \
			$(MAKE) -C $$dir LAUNCH_ROOT=$(LAUNCH_ROOT) $@ || exit 1; \
		fi \
	done

.PHONY: all debug release clean test install
