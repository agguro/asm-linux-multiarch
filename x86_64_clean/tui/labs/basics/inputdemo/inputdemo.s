/*
 * ============================================================================
 * Name        : inputdemo.s
 * Credits     : Buffer clearing routine adapted from GunnerInc. 
 * Description : Asks for input, handles buffer overflows by clearing STDIN,
 *               and echoes the result back to stdout.
 *
 * Feature     : Position Independent Code (PIC) using RIP-relative addressing.
 *
 * Build Sequence:
 * 1. Assemble:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include -o inputdemo.o inputdemo.s
 *
 * 2. Link (PIE):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o inputdemo inputdemo.o
 * ============================================================================
 */

.nolist
    .include "unistd.inc"
.list

.equ BUFFERLENGTH, 15

.section .bss
    .align 16
    .Lbuffer_start:  .skip BUFFERLENGTH
    .Lbuffer_dummy:  .skip 1

.section .rodata
    .Lquestion_start: 
        .ascii "Enter text (max 15 chars): "
    .equ .Lquestion_len, . - .Lquestion_start

.section .text
.globl _start

_start:
    # --- Print the QUESTION ---
    leaq    .Lquestion_start(%rip), %rsi
    movq    $.Lquestion_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # --- Read the answer ---
    leaq    .Lbuffer_start(%rip), %rsi
    movq    $BUFFERLENGTH, %rdx
    movq    $stdin, %rdi
    movq    $read, %rax
    syscall
    
    # Save bytes read to use as length for .Lwrite_answer later
    movq    %rax, %r15
    
    # --- Check for Buffer Overflow ---
    cmpq    $BUFFERLENGTH, %rax
    jl      .Lwrite_answer
    
    # Check if last byte is Line Feed (10)
    leaq    .Lbuffer_start(%rip), %rsi
    movb    -1(%rsi, %rax), %bl      
    cmpb    $10, %bl
    je      .Lwrite_answer

    # --- Clear STDIN pipe ---
.Lclear_stdin_loop:
    leaq    .Lbuffer_dummy(%rip), %rsi
    movq    $1, %rdx
    movq    $stdin, %rdi
    movq    $read, %rax
    syscall
    
    cmpb    $10, (%rsi)              
    jne     .Lclear_stdin_loop

.Lwrite_answer:
    movb    $10, %al                    # Load ASCII 10 (Line Feed) into AL register
    leaq    .Lbuffer_dummy(%rip), %rdi  # Load the address of the buffer
    movb    %al, (%rdi)                 # Store the byte into that address
    leaq    .Lbuffer_start(%rip), %rsi
    movq    %r15, %rdx                     # original RAX into RDX
    inc     %rdx                           # plus 1 for EOL
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    
    xorq    %rdi, %rdi
    movq    $exit, %rax
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
