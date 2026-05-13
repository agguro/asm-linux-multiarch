# name        : scalar_addarrays.s
# description : Addition of arrays using scalar operations (one by one)
# C calling   : extern "C" void scalar_addarrays(float *dest, float *src1, float *src2, int n);

.section .text

.globl scalar_addarrays
.type scalar_addarrays, @function
.align 16

scalar_addarrays:
    # rdi = dest, rsi = src1, rdx = src2, rcx = n
    testq %rcx, %rcx            # Check if n == 0
    jz .Ldone

.Lloop:
    vmovss (%rsi), %xmm0        # Load 1 float from src1
    vaddss (%rdx), %xmm0, %xmm1 # xmm1 = xmm0 + (1 float from src2)
    vmovss %xmm1, (%rdi)        # Store 1 float in dest

    addq $4, %rsi               # Advance pointers by 4 bytes (1 float)
    addq $4, %rdx
    addq $4, %rdi
    decq %rcx                   # Decrement counter
    jnz .Lloop                  # Repeat if rcx > 0

.Ldone:
    ret

.size scalar_addarrays, .-scalar_addarrays
.section .note.GNU-stack,"",@progbits
