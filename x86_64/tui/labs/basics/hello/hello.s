/*
 * ============================================================================
 * Name        : hello.s
 * Description : Basic x86_64 Linux assembly demonstration using system 
 *               calls to write to stdout and exit.
 *
 * Feature     : Position Independent Code (PIC). This implementation uses
 *               RIP-relative addressing to ensure the code can be loaded
 *               at any virtual address (PIE compatible).
 *
 * Build Sequence:
 * 1. Assemble:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=hello.lst hello.s -o hello.o
 *
 * 2. Link (Position Independent Executable):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 \
 * -o hello hello.o
 *
 * Note: No external library dependencies required.
 * ============================================================================
 */

.nolist
    .include "unistd.inc"       /* for stdout, write and exit */
.list

/* read-only data */
.section .rodata
    .Lthe_message: .ascii  "Hello world!\n"
    .equ .Lthe_message_len, . - .Lthe_message

    /*
     * in case .asciz then you must use:
     * .equ the_message_len, . - the_message - 1
     * minus one to exclude trailing zero.
     */

.section .text
.globl  _start

_start:
    movq    $.Lthe_message_len, %rdx
    leaq    .Lthe_message(%rip), %rsi
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    xorq    %rdi,%rdi
    movq    $exit, %rax
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
