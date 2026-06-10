/*
 **************************************************************************
 * Name          : uuid.s
 * Description   : Generates a pseudo-random UUID-style string (PIC).
 *
 * Build Sequence:
 * 1. Assemble: as --64 -g -I ../../../include uuid.s -o uuid.o
 * 2. Link:     ld -m elf_x86_64 -pie -o uuid uuid.o print_stringz.o strlen.o
 *
 * Strategy:
 * 1. Use 'rdtsc' as a hardware seed for a fast 64-bit XorShift generator.
 * 2. Fill a pre-formatted buffer that already contains hyphens.
 * 3. Use 'print_stringz' for an efficient, single system call output.
 * **************************************************************************
 */
 
.nolist
    .include "unistd.inc"
.list

.extern print_stringz

.section .data
    # The formatted buffer with pre-baked hyphens
    uuid_str:
    .g1:      .fill 8, 1, 0
              .byte '-'
    .g2:      .fill 4, 1, 0
              .byte '-'
    .g3:      .fill 4, 1, 0
              .byte '-'
    .g4:      .fill 4, 1, 0
              .byte '-'
    .g5:      .fill 12, 1, 0
    .eol:     .byte 10, 0          # Newline + Null for print_stringz

    .align 8
    # Use labels directly in the table. 
    # To keep it simple and avoid relocation errors, we use quads.
    uuid_layout:
        .quad .g1
        .quad 8
        .quad .g2
        .quad 4
        .quad .g3
        .quad 4
        .quad .g4
        .quad 4
        .quad .g5
        .quad 12
    .equ LAYOUT_ENTRIES, 5


.section .text
    .globl _start

_start:
    leaq    uuid_layout(%rip), %rbx  # Get absolute address of table via RIP
    movq    $LAYOUT_ENTRIES, %r12    # Number of groups

.Lnext_group:
    # 1. Load the pointer to the group buffer
    movq    (%rbx), %rdi            
    
    # 2. Load the nibble count
    movq    8(%rbx), %rcx           
    
    # 3. Fill the group
    call    .Lfill_group
    
    # 4. Advance: 2 quads = 16 bytes
    addq    $16, %rbx               
    decq    %r12
    jnz     .Lnext_group

    # Print result using library
    movl    $stdout, %edi
    leaq    uuid_str(%rip), %rsi
    call    print_stringz
    
    # Exit
    movl    $exit, %eax
    xorl    %edi, %edi
    syscall
    
    
# --- Subroutines ---

.Lfill_group:
    cld
.Lloop:
    pushq   %rcx
    pushq   %rdi
    call    .LGenerateRandomNibble
    popq    %rdi
    popq    %rcx
    stosb                           # Store AL at [RDI]
    loop    .Lloop
    ret

.LGenerateRandomNibble:
    rdtsc
    shlq    $32, %rdx
    orq     %rdx, %rax
    call    .LXorShift
    andq    $0x0F, %rax
    
    addb    $'0', %al
    cmpb    $'9', %al
    jbe     .Ldone
    addb    $39, %al                # Adjust for 'a'-'f'
.Ldone:
    ret

.LXorShift:
    movq    %rax, %rdx
    shlq    $13, %rax
    xorq    %rdx, %rax
    movq    %rax, %rdx
    shrq    $17, %rax
    xorq    %rdx, %rax
    movq    %rax, %rdx
    shlq    $5, %rax
    xorq    %rdx, %rax
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
