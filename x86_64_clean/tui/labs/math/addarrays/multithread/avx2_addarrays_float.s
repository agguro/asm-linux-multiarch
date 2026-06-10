# name        : avx_addarrays_float.s
# description : Fixed addition of exactly 8 floats using AVX2
# C calling   : extern "C" void avx2_addarrays(float *dest, float *src1, float *src2);

.section .text
.globl avx2_addarrays_float
.type avx2_addarrays_float, @function
.align 32

avx2_addarrays_float:
    pushq %rbp
    movq  %rsp, %rbp

    # We use r8 to keep track of the remaining elements
    movq %rcx, %r8
    shrq $3, %rcx           # Divide count by 8 (YMM holds 8 floats)
    jz .tail                # If less than 8, go straight to scalar tail

.loop:
    vmovups (%rsi), %ymm0   # Load 8 floats from src1
    vaddps  (%rdx), %ymm0, %ymm1 # Floating point add 8 floats
    vmovups %ymm1, (%rdi)   # Store 8 results to dest

    addq $32, %rsi          # Move pointers (8 * 4 bytes = 32)
    addq $32, %rdx
    addq $32, %rdi

    decq %rcx
    jnz .loop

.tail:
    andq $7, %r8            # Get remainder (count % 8)
    jz .done
.tloop:
    vmovss (%rsi), %xmm0    # Scalar load
    vaddss (%rdx), %xmm0, %xmm0
    vmovss %xmm0, (%rdi)
    addq $4, %rsi
    addq $4, %rdx
    addq $4, %rdi
    decq %r8
    jnz .tloop

.done:
    vzeroupper
    leave
    ret

.size avx2_addarrays_float, .-avx2_addarrays_float
.section .note.GNU-stack,"",@progbits
