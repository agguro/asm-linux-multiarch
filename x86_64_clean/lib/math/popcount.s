/* **************************************************************************
 * Name         : popcount.s
 * Assemble     : as --64 popcount.s -o popcount.o
 * Description  : Counts either set bits (1s) or clear bits (0s) in a register.
 *
 * Input        : %rdi = value to analyze
 * %rsi = target bit type (0 or 1)
 * Output       : %rax = total count
 *
 * Strategy:
 * This function avoids conditional jumps by using the 'test' and 'setz' 
 * instructions to create a bit-mask. If the user requests a count of 0s, 
 * the function XORs the value with -1 (NOT logic) before passing it to the 
 * hardware 'popcnt' instruction.
 * ************************************************************************** */

.section .text
.globl popcount
.type popcount, @function

popcount:
    movq    %rdi, %rax
    
    # 1. Handle the 0-count request without branching.
    # Logic: If %rsi is 0, we flip all bits in %rax to count zeros as ones.
    
    testq   %rsi, %rsi          # Is the requested bit 1?
    setz    %dl                 # %dl = 1 if user requested 0, else 0
    movzbq  %dl, %rdx           # Zero extend to 64-bit
    negq    %rdx                # if 1 -> 0xFF...FF (all 1s), if 0 -> 0
    
    xorq    %rdx, %rax          # Bitwise NOT if rdx is all 1s, else no change

    # 2. Hardware Population Count
    # This instruction calculates the number of set bits (Hamming Weight).
    popcntq %rax, %rax        
    
    ret

.size popcount, .-popcount
.section .note.GNU-stack,"",@progbits
