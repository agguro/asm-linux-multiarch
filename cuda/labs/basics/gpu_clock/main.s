# -----------------------------------------------------------------------------
# x86_64 CUDA Clock Cycle Test
# -----------------------------------------------------------------------------
.nolist
    .include "unistd.inc"
.list

.section .text
.globl _start

_start:
    pushq   %rbp
    movq    %rsp, %rbp
    andq    $-16, %rsp
    subq    $512, %rsp

    # 1. Initialize
    xorl    %edi, %edi; call cuInit@PLT
    leaq    16(%rsp), %rdi; xorl %esi, %esi; call cuDeviceGet@PLT
    leaq    24(%rsp), %rdi; xorl %esi, %esi; movl 16(%rsp), %edx; call cuCtxCreate_v2@PLT

    # 2. Load
    leaq    h_module(%rip), %rdi; leaq kernel_bin(%rip), %rsi; call cuModuleLoadData@PLT
    leaq    h_func(%rip), %rdi; movq h_module(%rip), %rsi; leaq kernel_name(%rip), %rdx; call cuModuleGetFunction@PLT

    # 3. Allocate
    movq    $1024, %rsi
    leaq    d_c(%rip), %rdi; call cuMemAlloc_v2@PLT

    # 4. Params
    movq    d_c(%rip), %rax; movq %rax, param_c(%rip)
    leaq    n_val(%rip), %rax; movq %rax, param_n(%rip)

    # 5. Launch (1 block, 1 thread)
    subq    $80, %rsp
    movq    $1, 0(%rsp)              # blockDimZ
    movq    $0, 8(%rsp)              # sharedMem
    movq    $0, 16(%rsp)             # hStream
    leaq    kernel_params(%rip), %rax
    movq    %rax, 24(%rsp)           # kernelParams
    movq    $0, 32(%rsp)             # extra

    movq    h_func(%rip), %rdi       
    movl    $1, %esi                 # gridDimX
    movl    $1, %edx; movl $1, %ecx
    movl    $1, %r8d                 # blockDimX
    movl    $1, %r9d
    call    cuLaunchKernel@PLT
    addq    $80, %rsp

    # Synchronize
    call    cuCtxSynchronize@PLT

    # 6. Copy Back
    leaq    h_c(%rip), %rdi
    movq    d_c(%rip), %rsi
    movq    $1024, %rdx
    call    cuMemcpyDtoH_v2@PLT

    # 7. Print Clock Results
    leaq    fmt_res(%rip), %rdi
    cvtss2sd h_c(%rip), %xmm0        # Start Clock
    cvtss2sd h_c+4(%rip), %xmm1      # End Clock
    movb    $2, %al
    call    printf@PLT

    xorq    %rdi, %rdi
    movq    $exit_group, %rax
    syscall

.section .rodata
kernel_bin:  .incbin "kernel.cubin"
kernel_name: .asciz  "gpu_clock"
fmt_res:     .asciz  "GPU Start Clock: %.0f\nGPU End Clock:   %.0f\n"

.section .data
.align 32
n_val:      .long   1
h_module:   .quad   0
h_func:     .quad   0
d_c:        .quad   0
param_a:    .quad   0; param_b: .quad 0; param_c: .quad 0; param_n: .quad 0
kernel_params: .quad param_a, param_b, param_c, param_n
.align 32
h_c:        .fill   256, 4, 0

.section .note.GNU-stack,"",@progbits
