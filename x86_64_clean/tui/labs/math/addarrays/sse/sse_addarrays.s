# name        : sse_addarrays.s
# description : Fixed addition of exactly 4 floats using SSE (XMM)
# C calling   : extern "C" void sse_addarrays(float *dest, float *src1, float *src2);

.section .text

.globl sse_addarrays
.type sse_addarrays, @function
.align 16

sse_addarrays:
    # rdi = dest, rsi = src1, rdx = src2
    # Standard System V ABI: arguments passed in rdi, rsi, rdx

    vmovaps (%rsi), %xmm0       # Load 4 floats (16-byte aligned)
    vmovaps (%rdx), %xmm1       # Load 4 floats (16-byte aligned)
    
    vaddps  %xmm1, %xmm0, %xmm2  # xmm2 = xmm0 + xmm1
    
    vmovaps %xmm2, (%rdi)       # Store 4 floats (16-byte aligned)

    ret

.size sse_addarrays, .-sse_addarrays
.section .note.GNU-stack,"",@progbits
