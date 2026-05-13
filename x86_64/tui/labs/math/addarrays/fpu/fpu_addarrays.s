# name        : fpu_addarrays.s
# description : Addition of arrays using the legacy x87 FPU stack
# C calling   : extern "C" void fpu_addarrays(float *dest, float *src1, float *src2, int n);

.section .text
.globl fpu_addarrays
.type fpu_addarrays, @function

fpu_addarrays:
    # rdi = dest, rsi = src1, rdx = src2, rcx = n
    testq %rcx, %rcx
    jz .Ldone

.Lloop:
    flds (%rsi)         # Load Single (float) from src1 and push onto FPU stack [st(0)]
    fadds (%rdx)        # Add Single (float) from src2 to st(0)
    fstps (%rdi)        # Store result as Single (float) and pop from FPU stack

    addq $4, %rsi       # Next float
    addq $4, %rdx
    addq $4, %rdi
    decq %rcx
    jnz .Lloop

.Ldone:
    ret

.size fpu_addarrays, .-fpu_addarrays
.section .note.GNU-stack,"",@progbits
