# name        : avx2_thread_bridge.s
# description : Unpacks thread arguments and calls the AVX2 worker
# target      : x86_64-linux

.section .text
.globl avx2_thread_bridge
.extern avx2_addarrays_float

avx2_thread_bridge:
    pushq %rbp
    movq  %rsp, %rbp

    # rdi is ptr to struct
    movq 0(%rdi),  %r8    # temp dest
    movq 8(%rdi),  %rsi   # src1
    movq 16(%rdi), %rdx   # src2
    movq 24(%rdi), %rcx   # count

    movq %r8, %rdi        # Worker expects dest in rdi
    call avx2_addarrays_float

    xorq %rax, %rax
    leave
    ret

.size avx2_thread_bridge, .-avx2_thread_bridge
.section .note.GNU-stack,"",@progbits
