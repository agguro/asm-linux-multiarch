#!/usr/bin/env bash
# ==============================================================================
# LOW-LEVEL FRAMEWORK: PROJECT GENERATOR WITH AUTOMATIC HARDLINKS
# FILEPATH: .blueprints/create_project.sh
# ==============================================================================

# Zorg dat we altijd weten waar de absolute repository root is
BLUEPRINT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$BLUEPRINT_DIR/.." && pwd)"

# Functie voor usage handleiding
usage() {
    echo "Usage: $0 <hub_directory> <project_name>"
    echo "Example: $0 projects ticker-gbm"
    echo "Example: $0 cuda complex-solver"
    exit 1
}

# Controleer of de juiste argumenten zijn meegegeven
if [ $# -ne 2 ]; then
    usage
fi

HUB_DIR="$1"
PROJECT_NAME="$2"
TARGET_PATH="$REPO_ROOT/$HUB_DIR/$PROJECT_NAME"

# 1. VALIDEER CONTEXT
if [ ! -d "$REPO_ROOT/$HUB_DIR" ]; then
    echo "CRITICAL: Hub directory '$HUB_DIR' does not exist in $REPO_ROOT"
    exit 1
fi

if [ -d "$TARGET_PATH" ]; then
    echo "CRITICAL: Project '$PROJECT_NAME' already exists at $TARGET_PATH"
    exit 1
fi

echo "=============================================================================="
echo "Creating Pure Assembly Project: [$PROJECT_NAME] inside [$HUB_DIR/]"
echo "=============================================================================="

# 2. BOUW DE MAPPENSTRUCTUUR
mkdir -p "$TARGET_PATH/kernels/$PROJECT_NAME"
mkdir -p "$TARGET_PATH/x86_64/$PROJECT_NAME"
mkdir -p "$TARGET_PATH/x86_64/include"
mkdir -p "$TARGET_PATH/x86_64/lib"

# 3. GENEREER LEGE ASSEMBLY EN PTX STUBS
# De GPU Kernel stub
cat << EOF > "$TARGET_PATH/kernels/$PROJECT_NAME/$PROJECT_NAME.ptx"
.version 7.0
.target sm_80
.address_size 64

.visible .entry ${PROJECT_NAME} (
    .param .u64 input_ptr
) {
    ret;
}
EOF

# De CPU Host stub
cat << EOF > "$TARGET_PATH/x86_64/$PROJECT_NAME/$PROJECT_NAME.s"
# ==============================================================================
# PURE x86_64 LINUX ASSEMBLY HOST
# ==============================================================================
.intel_syntax noprefix

.section .rodata
    msg: .string "Initializing ${PROJECT_NAME} host...\n"

.section .text
.global _start

_start:
    # Schrijf init boodschap naar stdout
    mov rax, 1
    mov rdi, 1
    lea rsi, [rip + msg]
    mov rdx, 32
    syscall

    # Exit program
    mov rax, 60
    xor rdi, rdi
    syscall
EOF

# De MakefileLists.mk stub voor je library snippets
cat << EOF > "$TARGET_PATH/x86_64/$PROJECT_NAME/MakefileLists.mk"
# ==============================================================================
# SNIPPET SUPPORT CONFIGURATION (Local MakefileLists.mk)
# Add your required snippets from x86_64/lib/ here.
# ==============================================================================
# LIB_SOURCES := print_stringz.s u64toa.s
LIB_SOURCES := 
EOF

echo "--> Base stubs and directory tree generated successfully."

# 4. SMEED DE ONBREEKBARE HARDLINKS
echo "--> Smeeding unbrekable hardlinks to central blueprints..."

# Project-Root Orchestrator
ln "$BLUEPRINT_DIR/submodule_root.mk" "$TARGET_PATH/Makefile"

# Layer Orchestrators
ln "$BLUEPRINT_DIR/layer_orchestrator.mk" "$TARGET_PATH/kernels/Makefile"
ln "$BLUEPRINT_DIR/layer_orchestrator.mk" "$TARGET_PATH/x86_64/Makefile"

# Universele Bladeren (Leaves)
ln "$BLUEPRINT_DIR/leaf_generic.mk" "$TARGET_PATH/kernels/$PROJECT_NAME/Makefile"
ln "$BLUEPRINT_DIR/leaf_generic.mk" "$TARGET_PATH/x86_64/$PROJECT_NAME/Makefile"

echo "=============================================================================="
echo "SUCCESS: Project [$PROJECT_NAME] is locked, linked and ready for deployment!"
echo "Location: $TARGET_PATH"
echo "=============================================================================="
