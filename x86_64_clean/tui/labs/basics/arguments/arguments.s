/*
 **************************************************************************
 * Name         : arguments.s
 * Description  : Demonstrates process argument parsing in x86-64 Linux.
 *
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=arguments.lst arguments.s -o arguments.o
 *
 * 2. Assemble Library Dependencies:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=strlen.lst ../../../lib/strlen.s -o strlen.o
 *
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=u64toa.lst ../../../lib/u64toa.s -o u64toa.o
 *
 * 3. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o arguments \
 * arguments.o strlen.o u64toa.o
 *
 *
 * Overview:
 * Unlike standard functions (where args are in registers), the Linux 
 * kernel places process arguments directly on the stack for the entry 
 * point (_start).
 *
 * Stack Layout at _start:
 * [rsp]        : argc (Number of arguments)
 * [rsp + 8]    : argv[0] (Pointer to program name string)
 * [rsp + 16]   : argv[1] (Pointer to first argument string)
 * ...
 * [rsp + N*8]  : NULL (End of argv array)
 *
 * Logic Flow:
 * 1. Pop argc into r12.
 * 2. Print argc using the u64toa conversion library.
 * 3. Pop argv[0] and print it as the program name.
 * 4. Loop through remaining stack items until a NULL pointer is found.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
.list

.section .bss
    .align 8
    buffer: .skip 32                # Buffer for numeric conversion

.section .rodata
    msg_argc: .asciz  "argc        : "
    .equ msg_argc_len, . - msg_argc - 1
    msg_prog: .asciz  "Programname : "
    .equ msg_prog_len, . - msg_prog - 1
    msg_argv: .asciz  "argv[]      : "
    .equ msg_argv_len, . - msg_argv - 1
    char_nl:  .ascii  "\n"
    char_sp:  .ascii  " "

.section .text
.globl  _start
.extern strlen
.extern u64toa

_start:
    # --- 1. Get ARGC ---
    popq    %r12                    # Stack top is argc

    # --- Print Label ---
    leaq    msg_argc(%rip), %rsi
    movq    $msg_argc_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # --- Convert and Print ARGC value ---
    movq    %r12, %rdi              # Arg1: value
    leaq    buffer(%rip), %rsi      # Arg2: buffer
    movq    $32, %rdx               # Arg3: size
    call    u64toa                  # Returns RSI=ptr, RDX=len

    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    leaq    char_nl(%rip), %rsi
    movq    $1, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # --- 2. Print Program Name (argv[0]) ---
    leaq    msg_prog(%rip), %rsi
    movq    $msg_prog_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    popq    %rdi                    # Pop argv[0] pointer
    pushq   %rdi                    # Save for write syscall
    call    strlen
    movq    %rax, %rdx
    popq    %rsi                    # Restore pointer to RSI
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    leaq    char_nl(%rip), %rsi
    movq    $1, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # --- 3. Print argv[] Label ---
    leaq    msg_argv(%rip), %rsi
    movq    $msg_argv_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # --- 4. Loop Remaining Arguments ---
1:  
    popq    %rdi                    # Get next argv[i] pointer
    testq   %rdi, %rdi              # Check for NULL terminator
    jz      2f                      # If NULL, we are finished

    pushq   %rdi
    call    strlen
    movq    %rax, %rdx
    popq    %rsi

    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    leaq    char_sp(%rip), %rsi
    movq    $1, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    jmp     1b                      # Process next argument

2:  # Cleanup and Exit
    leaq    char_nl(%rip), %rsi
    movq    $1, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    xorq    %rdi, %rdi              # Exit code 0
    movq    $exit, %rax             # sys_exit
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
