# name        : avx512_addarrays.s
# description : AVX-512 floating point addition (512-bit)
# C calling   : extern "C" void avx512_addarrays(float *dest, float *src1, float *src2);

.section .text
.globl avx512_addarrays
.type avx512_addarrays, @function
.align 64

avx512_addarrays:
    # rdi = dest, rsi = src1, rdx = src2
    
    # Load 512-bits (16 floats)
    vmovups (%rsi), %zmm0      # Use ZMM for 512-bit width
    vmovups (%rdx), %zmm1
    
    # Perform addition
    vaddps  %zmm1, %zmm0, %zmm2
    
    # Store result
    vmovups %zmm2, (%rdi)

    # vzeroupper is still good practice to avoid transitions if returning to SSE
    vzeroupper 
    ret

.size avx512_addarrays, .-avx512_addarrays
.section .note.GNU-stack,"",@progbits
