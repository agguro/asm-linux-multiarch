# ==============================================================================
# ASM-LINUX-MULTIARCH: ABSOLUTE TOP ORCHESTRATOR (asm-multiarch/Makefile)
# ==============================================================================

# 1. TOOLCHAIN DETECTION & VALIDATION
PTXAS    := $(shell which ptxas 2>/dev/null)
NVDISASM := $(shell which nvdisasm 2>/dev/null)

ifeq ($(PTXAS),)
    $(error CRITICAL: 'ptxas' not found in $$PATH. Please install nvidia-cuda-toolkit!)
endif

ifeq ($(NVDISASM),)
    $(error CRITICAL: 'nvdisasm' not found in $$PATH. Please install nvidia-cuda-toolkit!)
endif

# 2. LAUNCH CONTEXT DETECTIE
# Als je op het allerhoogste niveau 'make' typt, is DEZE map de absolute launch root.
ifndef LAUNCH_ROOT
    export LAUNCH_ROOT := $(abspath $(CURDIR))/
endif

GLOBAL_BUILD := $(LAUNCH_ROOT)build
GLOBAL_BIN   := $(LAUNCH_ROOT)bin

# 3. KOGELVRIJE HUB DISCOVERY
# Ontdek puur de directe hoofdmappen die een Makefile bevatten (1 niveau diep, zoals projects, cuda, etc.)
# We filteren '.' en '..' uit om recursie op de top fysiek onmogelijk te maken.
ALL_DIRS := $(patsubst %/,%,$(dir $(wildcard */Makefile)))
SUBDIRS  := $(filter-out . ..,$(ALL_DIRS))

all: debug

# 4. DIRECT EXECUTION LOOP (Stuwt de LAUNCH_ROOT dominant omlaag naar de hubs)
debug release clean test install: directories
	@for dir in $(SUBDIRS); do \
		if [ -d $$dir ] && [ -f $$dir/Makefile ]; then \
			echo "=============================================================================="; \
			echo "Top-Root -> Entering Hub Layer: ./$$dir -> Target: $@"; \
			echo "=============================================================================="; \
			$(MAKE) -C $$dir LAUNCH_ROOT=$(LAUNCH_ROOT) $@ || exit 1; \
		fi \
	done

# 5. UTILITIES
directories:
	@mkdir -p $(GLOBAL_BUILD)
	@mkdir -p $(GLOBAL_BIN)

deep_clean:
	@echo "Purging centralized build and binary directories from absolute root $(LAUNCH_ROOT)..."
	rm -rf $(GLOBAL_BUILD) $(GLOBAL_BIN)

.PHONY: all debug release clean test install directories deep_clean
