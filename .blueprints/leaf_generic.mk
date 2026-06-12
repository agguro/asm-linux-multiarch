# ==============================================================================
# LOW-LEVEL FRAMEWORK: UNIVERSELE LEAF ENGINE (GPU & CPU AUTODETECT)
# BPI-BLUEPRINT: .blueprints/leaf_generic.mk
# ==============================================================================

CURRENT_DIR   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NAME          := $(notdir $(CURRENT_DIR))
SRC_ROOT      := $(patsubst %/x86_64/$(NAME)/,%,$(patsubst %/kernels/$(NAME)/,%,$(CURRENT_DIR)/))

# LAUNCH_ROOT context-bepaling
ifndef LAUNCH_ROOT
    export LAUNCH_ROOT := $(abspath $(CURRENT_DIR)/../../../)/
endif

# Categorie scan via fysieke pad-analyse
ifneq ($(findstring /projects/,$(CURRENT_DIR)),)
    CATEGORY := projects
else ifneq ($(findstring /cuda/,$(CURRENT_DIR)),)
    CATEGORY := cuda
else
    CATEGORY := .
endif

MODE          ?= debug
LAST_LAUNCH   := $(notdir $(patsubst %/,%,$(LAUNCH_ROOT)))
PROJECT_NAME  := $(notdir $(abspath $(SRC_ROOT)))

# BRONCODE DETECTIE (Bepaalt de modus van deze leaf)
HAS_PTX       := $(wildcard $(CURRENT_DIR)/$(NAME).ptx)
HAS_ASM       := $(wildcard $(CURRENT_DIR)/$(NAME).s)

# ANKERING VAN DE BUILD- EN BIN-TREES
ifeq ($(CATEGORY),.)
    BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/x86_64/$(NAME)
    BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/x86_64/$(NAME)
    KERNEL_BUILD := $(LAUNCH_ROOT)build/$(MODE)/kernels/$(NAME)
else
    ifeq ($(LAST_LAUNCH),$(PROJECT_NAME))
        BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/x86_64/$(NAME)
        BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/x86_64/$(NAME)
        KERNEL_BUILD := $(LAUNCH_ROOT)build/$(MODE)/kernels/$(NAME)
    else
        BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/$(CATEGORY)/x86_64/$(NAME)
        BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/$(CATEGORY)/x86_64/$(NAME)
        KERNEL_BUILD := $(LAUNCH_ROOT)build/$(MODE)/$(CATEGORY)/kernels/$(NAME)
    endif
endif

# Fix build-pad als we een pure kernel aan het bouwen zijn
ifneq ($(HAS_PTX),)
    ifeq ($(LAST_LAUNCH),$(PROJECT_NAME))
        BUILD_DIR := $(LAUNCH_ROOT)build/$(MODE)/kernels/$(NAME)
    else
        BUILD_DIR := $(LAUNCH_ROOT)build/$(MODE)/$(CATEGORY)/kernels/$(NAME)
    endif
endif

# Paden naar headers, libraries en componenten
KERNEL_DIR   := $(SRC_ROOT)/kernels/$(NAME)
INC_DIR      := $(SRC_ROOT)/x86_64/include
LIB_DIR      := $(SRC_ROOT)/x86_64/lib

# TOOLCHAIN CONFIGURATIE
AS           := as
LD           := ld
PTXAS         := ptxas
NVDISASM      := nvdisasm

.SUFFIXES:
%: %.c

ASFLAGS      := --64 -msyntax=att -mmnemonic=att -I$(BUILD_DIR) -I$(INC_DIR) -I$(LIB_DIR) -I$(KERNEL_DIR) -I$(KERNEL_BUILD)
LDFLAGS      := -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L/usr/local/cuda/lib64 -L/usr/lib/x86_64-linux-gnu -lcuda -lc -lcrypto -lssl
PTXASFLAGS    := -v --gpu-name=sm_80

ifeq ($(MODE),debug)
    ASFLAGS    += -g
    LDFLAGS    += -g
    PTXASFLAGS += --generate-line-info
    MSG        := "Build Mode: DEBUG"
else
    LDFLAGS    += -s
    MSG        := "Build Mode: RELEASE"
endif

all: debug

# PIPELINE SELECTIE OP BASIS VAN DETECTIE
debug release: directories
ifneq ($(HAS_PTX),)
	@$(MAKE) -f $(lastword $(MAKEFILE_LIST)) LAUNCH_ROOT=$(LAUNCH_ROOT) MODE=$(MODE) build_kernel
endif
ifneq ($(HAS_ASM),)
	@$(MAKE) -f $(lastword $(MAKEFILE_LIST)) LAUNCH_ROOT=$(LAUNCH_ROOT) MODE=$(MODE) build_host
endif

# --- GPU PIPELINE ---
PTX_SRC   := $(CURRENT_DIR)/$(NAME).ptx
PTX_OBJ   := $(BUILD_DIR)/$(NAME).cubin
SASS_DUMP := $(BUILD_DIR)/$(NAME).sass

build_kernel: directories $(PTX_OBJ) $(SASS_DUMP)

$(PTX_OBJ): $(PTX_SRC) | directories
	$(PTXAS) $(PTXASFLAGS) $(PTX_SRC) -o $(PTX_OBJ)
	@echo "--> GPU Kernel $(NAME).ptx assembled successfully into $(PTX_OBJ)!"

$(SASS_DUMP): $(PTX_OBJ)
	$(NVDISASM) -g $(PTX_OBJ) > $(SASS_DUMP)
	@echo "--> SASS file generated successfully: $(SASS_DUMP)"

# --- CPU HOST PIPELINE ---
SRC_HOST  := $(CURRENT_DIR)/$(NAME).s
OBJ       := $(BUILD_DIR)/$(NAME).o
LST       := $(BUILD_DIR)/$(NAME).lst
TARGET    := $(BIN_DIR)/$(NAME)

-include $(CURRENT_DIR)/MakefileLists.mk
LIB_SOURCES_BARE := $(notdir $(LIB_SOURCES))
LIB_SOURCES_FULL := $(addprefix $(LIB_DIR)/,$(LIB_SOURCES_BARE))
EXTRA_OBJS   := $(patsubst $(LIB_DIR)/%.s,$(BUILD_DIR)/obj_%.o,$(LIB_SOURCES_FULL))
ALL_OBJS     := $(OBJ) $(EXTRA_OBJS)

build_host: info check_kernel $(TARGET)

info:
	@echo "=============================================================================="
	@echo $(MSG) "for target [$(NAME)]"
	@echo "Launch Root:  $(LAUNCH_ROOT)"
	@echo "Category:     $(CATEGORY)"
	@echo "Host Source:  $(SRC_HOST)"
	@if [ -n "$(LIB_SOURCES_BARE)" ]; then echo "Lib Sources:  $(LIB_SOURCES_BARE) (resolved via $(LIB_DIR)/)"; fi
	@echo "Target:       $(TARGET)"
	@echo "=============================================================================="

check_kernel:
	@if [ -d $(KERNEL_DIR) ] && [ -f $(KERNEL_DIR)/Makefile ]; then \
		$(MAKE) -C $(KERNEL_DIR) LAUNCH_ROOT=$(LAUNCH_ROOT) MODE=$(MODE) build_kernel; \
	fi

$(OBJ): $(SRC_HOST) check_kernel | directories
	$(AS) $(ASFLAGS) -c $(SRC_HOST) -o $(OBJ) -a=$(LST)

$(BUILD_DIR)/obj_%.o: $(LIB_DIR)/%.s | directories
	$(AS) $(ASFLAGS) -c $< -o $@

$(TARGET): $(ALL_OBJS) | directories
	$(LD) $(LDFLAGS) $(ALL_OBJS) -o $(TARGET)
	@echo "--> Host Binary $(NAME) linked successfully!"

# --- UTILITIES ---
directories:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(BUILD_DIR)

clean:
	@echo "Cleaning up build paths for $(NAME)..."
	rm -rf $(BUILD_DIR) $(BIN_DIR)

test:
ifneq ($(HAS_ASM),)
	@$(TARGET)
endif

install:
ifneq ($(HAS_ASM),)
	@mkdir -p $(HOME)/asm-multiarch/bin/cuda/$(CATEGORY)
	@cp $(TARGET) $(HOME)/asm-multiarch/bin/cuda/$(CATEGORY)/$(NAME)
endif

.PHONY: all debug release clean test install build_kernel build_host info check_kernel directories
