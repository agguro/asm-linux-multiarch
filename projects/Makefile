# ==============================================================================
# ASM-LINUX-FRAMEWORK: UNIVERSELE LAYER HUB (Kopieerbaar naar projects/, cuda/, etc.)
# ==============================================================================

# 1. LAUNCH CONTEXT DETECTIE
# Als LAUNCH_ROOT niet van bovenaf is meegegeven, is DEZE huidige map de baas
# (of dat nu projects/, cuda/, of een andere folder is).
ifndef LAUNCH_ROOT
    export LAUNCH_ROOT := $(abspath $(CURDIR))/
endif

GLOBAL_BUILD := $(LAUNCH_ROOT)build
GLOBAL_BIN   := $(LAUNCH_ROOT)bin

# 2. KOGELVRIJE DISCOVERY
# Ontdek alle submappen (de submodules/leafs) binnen deze specifieke hub
ALL_DIRS := $(patsubst %/,%,$(dir $(wildcard */Makefile)))
SUBDIRS  := $(filter-out . ..,$(ALL_DIRS))

all: debug

# 3. DIRECT EXECUTION LOOP (Geeft de LAUNCH_ROOT dwingend door aan de submodules)
debug release clean test install: directories
	@for dir in $(SUBDIRS); do \
		if [ -d $$dir ] && [ -f $$dir/Makefile ]; then \
			echo "=============================================================================="; \
			echo "Hub Root [$(notdir $(patsubst %/,%,$(LAUNCH_ROOT)))] -> Target Directory: $$dir -> Target: $@"; \
			echo "=============================================================================="; \
			$(MAKE) -C $$dir LAUNCH_ROOT=$(LAUNCH_ROOT) $@ || exit 1; \
		fi \
	done

# 4. UTILITIES
directories:
	@mkdir -p $(GLOBAL_BUILD)
	@mkdir -p $(GLOBAL_BIN)

deep_clean:
	@echo "Removing centralized build and binary directories from $(LAUNCH_ROOT)..."
	rm -rf $(GLOBAL_BUILD) $(GLOBAL_BIN)

.PHONY: all debug release clean test install directories deep_clean
