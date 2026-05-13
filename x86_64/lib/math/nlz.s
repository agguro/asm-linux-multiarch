/*
 **************************************************************************
 * Name        : nlz.s
 * Description : Count leading zeros (64-bit). 
 * Uses the Branch-Free "Bit-Fill" method for performance.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = 64-bit value to analyze
 * Output      : %rax = count of leading zeros (0-64)
 * **************************************************************************
 */

.section .text
   
.globl nlz
.type nlz, @function
nlz:
    # We treat this as a "leaf function" (no calls to other functions).
    # Therefore, we skip the %rbp prologue to maximize execution speed.

    movq    %rdi, %rax
    testq   %rax, %rax
    jnz     .Lstart_nlz
    movq    $64, %rax
    ret

.Lstart_nlz:
    # Bit-Fill: Propagate the highest '1' bit to the right
    movq    %rax, %rdx
    shrq    $1, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $2, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $4, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $8, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $16, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $32, %rdx
    orq     %rdx, %rax

    # RAX is now a contiguous block of 1s (e.g., 00001111)
    popcntq %rax, %rax        # Count set bits (Significant Width)
    movq    $64, %rdx
    subq    %rax, %rdx        # 64 - Width = Leading Zeros
    movq    %rdx, %rax
    ret

.size nls, .-nlz
.section .note.GNU-stack,"",@progbits
