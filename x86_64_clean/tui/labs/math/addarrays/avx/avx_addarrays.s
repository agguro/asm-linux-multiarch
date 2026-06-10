# name        : avx_addarrays.s
# description : Fixed addition of exactly 8 floats using AVX2
# C calling   : extern "C" void avx2_addarrays(float *dest, float *src1, float *src2);

.section .text

.globl avx_addarrays
.type avx_addarrays, @function
.align 32

avx_addarrays:
    # rdi = dest, rsi = src1, rdx = src2
    # No %rcx (n) used. We process exactly 8 floats.

    vmovups (%rsi), %ymm0       # Load exactly 8 floats (32 bytes)
    vmovups (%rdx), %ymm1       # Load exactly 8 floats (32 bytes)
    
    vaddps  %ymm1, %ymm0, %ymm2  # Parallel Add: ymm2 = ymm0 + ymm1
    
    vmovups %ymm2, (%rdi)       # Store 8 results to dest

    vzeroupper                  # Clear upper halves of YMM for ABI safety
    ret

.size avx_addarrays, .-avx_addarrays
.section .note.GNU-stack,"",@progbits
