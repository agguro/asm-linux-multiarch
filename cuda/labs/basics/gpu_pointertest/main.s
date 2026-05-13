.section .text
.globl _start

_start:
    pushq   %rbp
    movq    %rsp, %rbp
    andq    $-16, %rsp
    subq    $256, %rsp

    # 1. CUDA Setup
    xorl    %edi, %edi; call cuInit@PLT
    leaq    16(%rsp), %rdi; xorl %esi, %esi; call cuDeviceGet@PLT
    leaq    24(%rsp), %rdi; xorl %esi, %esi; movl 16(%rsp), %edx; call cuCtxCreate_v2@PLT
    leaq    h_mod(%rip), %rdi; leaq k_bin(%rip), %rsi; call cuModuleLoadData@PLT
    leaq    h_fn(%rip), %rdi; movq h_mod(%rip), %rsi; leaq k_name(%rip), %rdx; call cuModuleGetFunction@PLT

    # 2. Alloc 24 bytes for C (to hold 3 pointers)
    movq    $8, %rsi; leaq 48(%rsp), %rdi; call cuMemAlloc_v2@PLT # d_a
    movq    $8, %rsi; leaq 56(%rsp), %rdi; call cuMemAlloc_v2@PLT # d_b
    movq    $24, %rsi; leaq 64(%rsp), %rdi; call cuMemAlloc_v2@PLT # d_c

    # 3. Print what the CPU thinks the pointers are
    leaq    p_msg_cpu(%rip), %rdi
    movq    48(%rsp), %rsi
    movq    56(%rsp), %rdx
    movq    64(%rsp), %rcx
    xorl    %eax, %eax; call printf@PLT

    # 4. Build Extra Buffer (32 bytes)
    movq    48(%rsp), %rax; movq %rax, 100(%rsp) # a
    movq    56(%rsp), %rax; movq %rax, 108(%rsp) # b
    movq    64(%rsp), %rax; movq %rax, 116(%rsp) # c
    movq    $1, 124(%rsp)                       # n

    # 5. Launch
    movq    $1, 130(%rsp); leaq 100(%rsp), %rax; movq %rax, 138(%rsp) # Buffer
    movq    $2, 146(%rsp); movq $32, 170(%rsp);  leaq 170(%rsp), %rax; movq %rax, 154(%rsp) # Size
    movq    $0, 162(%rsp) # End

    movq    h_fn(%rip), %rdi
    movl    $1, %esi; movl $1, %edx; movl $1, %ecx; movl $1, %r8d; movl $1, %r9d
    movq    $1, 0(%rsp); movq $0, 8(%rsp); movq $0, 16(%rsp); movq $0, 24(%rsp)
    leaq    130(%rsp), %rax; movq %rax, 32(%rsp)
    call    cuLaunchKernel@PLT
    call    cuCtxSynchronize@PLT

    # 6. Copy 24 bytes back from d_c
    leaq    180(%rsp), %rdi # local buffer
    movq    64(%rsp), %rsi  # d_c
    movq    $24, %rdx
    call    cuMemcpyDtoH_v2@PLT

    # 7. Print what the GPU thinks the pointers were
    leaq    p_msg_gpu(%rip), %rdi
    movq    180(%rsp), %rsi
    movq    188(%rsp), %rdx
    movq    196(%rsp), %rcx
    xorl    %eax, %eax; call printf@PLT

    xorq    %rdi, %rdi; movq $60, %rax; syscall

.section .rodata
k_bin:   .incbin "kernel.cubin"
k_name:  .asciz "pointertest"
p_msg_cpu: .asciz "CPU Pointers: A=%p, B=%p, C=%p\n"
p_msg_gpu: .asciz "GPU Pointers: A=%p, B=%p, C=%p\n"

.section .data
h_mod: .quad 0; h_fn: .quad 0