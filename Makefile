# ==============================================================================
# ASM-LINUX-FRAMEWORK: UNIVERSELE ORCHESTRATOR
# ==============================================================================

# 1. DYNAMIC DISCOVERY & PARAMETERS
# Zoekt flexibel naar submappen met een Makefile (tot 2 niveaus diep)
SUBDIRS      := $(patsubst %/,%,$(dir $(shell find . -mindepth 2 -maxdepth 2 -name Makefile)))

# Als we op het hoogste niveau starten, setten we de wet voor de PWD.
# Indien al geëxporteerd door een hogere repo, blijft de oorspronkelijke PARENTROOT staan.
ifndef PARENTROOT
    export PARENTROOT := $(CURDIR)/
endif

GLOBAL_BUILD := $(PARENTROOT)build
GLOBAL_BIN   := $(PARENTROOT)bin

all: debug

# 2. DIRECT EXECUTION LOOP
debug release clean test: directories
	@for dir in $(SUBDIRS); do \
		echo "=============================================================================="; \
		echo "Entering Target Directory: $$dir -> Target: $@"; \
		echo "=============================================================================="; \
		$(MAKE) -C $$dir $@ || exit 1; \
	done

# 3. UTILITIES
directories:
	@mkdir -p $(GLOBAL_BUILD)
	@mkdir -p $(GLOBAL_BIN)

deep_clean:
	@echo "Removing centralized build and binary directories..."
	rm -rf $(GLOBAL_BUILD) $(GLOBAL_BIN)

.PHONY: all debug release clean test directories deep_clean