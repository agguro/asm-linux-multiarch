# ==============================================================================
# ASM-LINUX-FRAMEWORK: UNIVERSELE ORCHESTRATOR (Root Makefile)
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

# 2. DYNAMIC DISCOVERY & PARAMETERS
SUBDIRS      := $(patsubst %/,%,$(dir $(shell find . -mindepth 2 -maxdepth 2 -name Makefile)))

# We zetten de wet voor de absolute project root vast en exporteren deze direct!
export PROJECT_ROOT := $(CURDIR)/

ifndef PARENTROOT
    export PARENTROOT := $(CURDIR)/
endif

GLOBAL_BUILD := $(PROJECT_ROOT)build
GLOBAL_BIN   := $(PROJECT_ROOT)bin

all: debug

# 3. DIRECT EXECUTION LOOP
debug release clean test: directories
	@for dir in $(SUBDIRS); do \
		echo "=============================================================================="; \
		echo "Entering Target Directory: $$dir -> Target: $@"; \
		echo "=============================================================================="; \
		$(MAKE) -C $$dir $@ || exit 1; \
	done

# 4. UTILITIES
directories:
	@mkdir -p $(GLOBAL_BUILD)
	@mkdir -p $(GLOBAL_BIN)

deep_clean:
	@echo "Removing centralized build and binary directories..."
	rm -rf $(GLOBAL_BUILD) $(GLOBAL_BIN)

.PHONY: all debug release clean test directories deep_clean

