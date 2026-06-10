# name        : avx2_addarrays.s
# description : True AVX2 integer addition (256-bit)
# C calling   : extern "C" void avx2_addarrays(int32_t *dest, int32_t *src1, int32_t *src2);

.section .text
.globl avx2_addarrays
.type avx2_addarrays, @function
.align 32

avx2_addarrays:
    # rdi = dest, rsi = src1, rdx = src2
    
    # Load 256-bits of integers (8 integers)
    vmovdqu (%rsi), %ymm0      # vmovdqu = Move Doubleword Unaligned
    vmovdqu (%rdx), %ymm1
    
    # AVX2 specific: Integer addition across 256-bit YMM
    vpaddd  %ymm1, %ymm0, %ymm2 # Parallel Add: 8x 32-bit integers
    
    # Store result
    vmovdqu %ymm2, (%rdi)

    vzeroupper                 # Critical for AVX -> SSE transition safety
    ret

.size avx2_addarrays, .-avx2_addarrays
.section .note.GNU-stack,"",@progbits
