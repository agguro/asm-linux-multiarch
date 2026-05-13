# -----------------------------------------------------------------------------
# Name:        hacker_bin2bcd
# Description: Double‑dabble (shift‑add‑3) conversion of 32‑bit binary → BCD.
# Input:       EDI = binary value (32 bits)
# Output:      RAX = BCD result (packed in 64 bits)
# Notes:       Branchless nibble‑wise add‑3 using Hacker’s Delight masking.
# -----------------------------------------------------------------------------

    .section .text
    .globl  hacker_bin2bcd
    .type   hacker_bin2bcd, @function

hacker_bin2bcd:
    xor     %rax, %rax                        # clear BCD accumulator
    mov     $32, %rcx                         # 32 bits to process

.L_bcdloop:
    mov     %rax, %rdx
    movabsq $0x3333333333333333, %r8
    add     %r8, %rdx      # add 3 to every nibble
    movabsq $0x8888888888888888, %r9
    test    %r9, %rdx      # detect nibble overflow

    shl     $1, %edi                          # shift next input bit into CF
    rcl     $1, %rax                          # rotate CF into BCD accumulator

    loop    .L_bcdloop
    ret

.size hacker_bin2bcd, . - hacker_bin2bcd
.section .note.GNU-stack,"",@progbits
