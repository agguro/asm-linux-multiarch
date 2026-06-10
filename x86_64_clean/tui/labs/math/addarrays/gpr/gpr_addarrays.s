# name        : gpr_addarrays.s
# description : Pure GPR addition (64-bit integers)
# C calling   : extern "C" void gpr_addarrays(long *dest, long *src1, long *src2, int n);

.section .text
.globl gpr_addarrays
.type gpr_addarrays, @function

gpr_addarrays:
    testq %rcx, %rcx            # Check if n == 0
    jz .Ldone

.Lloop:
    movq (%rsi), %rax           # READ: Load 8 bytes (64-bit word) from memory into GPR
    addq (%rdx), %rax           # ADD: Add 8 bytes from second array to RAX
    movq %rax, (%rdi)           # STORE: Write result back to memory

    addq $8, %rsi               # Pointer arithmetic (8 bytes per long)
    addq $8, %rdx
    addq $8, %rdi
    decq %rcx                   # Loop control
    jnz .Lloop

.Ldone:
    ret

.size gpr_addarrays, .-gpr_addarrays
.section .note.GNU-stack,"",@progbits
