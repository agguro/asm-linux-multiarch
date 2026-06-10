/*
 **************************************************************************
 * Name         : rotatebits.s
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * as --64 -g --noexecstack -I ../../../include \
 * -al=rotatebits.lst rotatebits.s -o rotatebits.o
 *
 * 2. Assemble Library Dependencies:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=print_stringz.lst ../../../lib/print_stringz.s -o print_stringz.o
 *
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=u64tobin.lst ../../../lib/u64tobin.s -o u64tobin.o
 *
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=signed_rotate.lst ../../../lib/signed_rotate.s -o signed_rotate.o
 *
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=strlen.lst ../../../lib/strlen.s -o strlen.o
 *
 * 3. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o rotatebits \
 * rotatebits.o print_stringz.o u64tobin.o signed_rotate.o strlen.o
 *
 *
 * Signed Bit-Window Rotation (x86-64 Assembly)
 * --------------------------------------------
 * This library provides a specialized circular rotation for bitstrings of 
 * arbitrary lengths (2 to 64 bits). Unlike standard ROL/ROR, this treats a
 * specific "window" as the universe.
 *
 * The Golden Rule: The most significant bit (the "Sign Bit") acts as a 
 * fixed wall. It never moves. Lower bits rotate circularly.
 *
 * Key Features:
 * - Custom Universe: ignores bits 7–63 if Bitlength is 7.
 * - Shortest Path: "Left 14" on 16-bits becomes "Right 1" internally.
 * - Implicit ABI: srol/sror use (Value, Bitlength, Count).
 * - No "Ghost Bits": Advanced masking prevents data leakage.
 *
 * How it Works:
 * - Normalization: Uses divq to find Count % Window.
 * - Isolation: Splits register into "The Wall" and "The Body".
 * - Manual Bridge: Catches bits "falling off" and wraps them manually.
 * - Re-assembly: ORs the fixed "Wall" back onto the "Body".
 *
 * Example Usage (6-bit rotation, Left 3):
 * movq $0b100100, %rdi  # Value
 * movq $6, %rsi         # Bitlength
 * movq $3, %rdx         # Count
 * call srol             # Result in %rax = 0b100001
 *
 * Technical Constraints:
 * - Min: 2 bits | Max: 64 bits
 * - Registers: r10-r13 internal (callee-saved restored).
 * **************************************************************************
 */

.equ VALUE, 0b1111111101100100   # Input data
.equ BITLEN, 6                   # Universe size (6 bits)

.nolist
    .include "unistd.inc"
.list

.section .rodata
    msg_orig:   .asciz "Original:       "
    msg_rot_l:  .asciz "\nRotate 3 Left:  "
    msg_rot_r:  .asciz "\nRotate 2 Right: "
    msg_nl:     .asciz "\n"

.section .bss
    .align 16
    reg64: .skip 65

.section .text
.globl _start

.extern print_stringz
.extern u64tobin
.extern srol           # part of signed_rotate.s
.extern sror           # part of signed_rotate.s

_start:
    # --- 1. ORIGINAL ---
    movq    $VALUE, %r12
    movq    $BITLEN, %r13

    movq    $stdout, %rdi
    leaq    msg_orig(%rip), %rsi
    call    print_stringz

    movq    %r12, %rdi
    leaq    reg64(%rip), %rsi
    movq    %r13, %rdx          # Display in BITLEN width
    call    u64tobin
    
    movq    $stdout, %rdi
    movq    %rax, %rsi
    call    print_stringz

    # --- 2. ROTATE 3 LEFT ---
    movq    $stdout, %rdi
    leaq    msg_rot_l(%rip), %rsi
    call    print_stringz

    movq    %r12, %rdi          # Value
    movq    %r13, %rsi          # Length
    movq    $3, %rdx            # Count
    call    srol

    movq    %rax, %rdi          # Prep for printing
    leaq    reg64(%rip), %rsi
    movq    %r13, %rdx
    call    u64tobin
    
    movq    $stdout, %rdi
    movq    %rax, %rsi
    call    print_stringz

    # --- 3. ROTATE 2 RIGHT ---
    movq    $stdout, %rdi
    leaq    msg_rot_r(%rip), %rsi
    call    print_stringz

    movq    %r12, %rdi          # Value
    movq    %r13, %rsi          # Length
    movq    $2, %rdx            # Count
    call    sror

    movq    %rax, %rdi
    leaq    reg64(%rip), %rsi
    movq    %r13, %rdx
    call    u64tobin

    movq    $stdout, %rdi
    movq    %rax, %rsi
    call    print_stringz

    # --- Exit ---
    movq    $stdout, %rdi
    leaq    msg_nl(%rip), %rsi
    call    print_stringz

    movq    $exit, %rax           # sys_exit
    xorq    %rdi, %rdi
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits

