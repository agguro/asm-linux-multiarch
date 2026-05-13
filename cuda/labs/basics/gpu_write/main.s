# -----------------------------------------------------------------------------
# CUDA Minimal Sanity Test - Write 42.0
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

    # 1. Initialize CUDA
    xorl    %edi, %edi; call cuInit@PLT
    leaq    16(%rsp), %rdi; xorl %esi, %esi; call cuDeviceGet@PLT
    leaq    24(%rsp), %rdi; xorl %esi, %esi; movl 16(%rsp), %edx; call cuCtxCreate_v2@PLT

    # 2. Load Module and Function
    leaq    h_module(%rip), %rdi; leaq kernel_bin(%rip), %rsi; call cuModuleLoadData@PLT
    leaq    h_func(%rip), %rdi; movq h_module(%rip), %rsi; leaq kernel_name(%rip), %rdx; call cuModuleGetFunction@PLT

    # 3. Allocate and Set Up d_c ONLY (we are just writing)
    movq    $4096, %rsi  # Just allocate 4KB for testing
    leaq    d_c(%rip), %rdi; call cuMemAlloc_v2@PLT

    # 4. Prepare Kernel Arguments
    # We must still provide placeholders for a and b because the PTX expects 4 params
    movq    d_c(%rip), %rax
    movq    %rax, param_a(%rip) # Placeholder
    movq    %rax, param_b(%rip) # Placeholder
    movq    %rax, param_c(%rip) # The real destination
    leaq    n_val(%rip), %rax; movq %rax, param_n(%rip)

    # 5. Launch Kernel (1 block, 1 thread)
    subq    $80, %rsp
    movq    $1, 0(%rsp)              # blockDimZ
    movq    $0, 8(%rsp)              # sharedMem
    movq    $0, 16(%rsp)             # hStream
    leaq    kernel_params(%rip), %rax
    movq    %rax, 24(%rsp)           # kernelParams
    movq    $0, 32(%rsp)             # extra

    movq    h_func(%rip), %rdi       # hFunc
    movl    $1, %esi                 # gridDimX
    movl    $1, %edx                 # gridDimY
    movl    $1, %ecx                 # gridDimZ
    movl    $1, %r8d                 # blockDimX
    movl    $1, %r9d                 # blockDimY
    call    cuLaunchKernel@PLT
    addq    $80, %rsp

    # Synchronize to ensure GPU is done
    call    cuCtxSynchronize@PLT

    # 6. Copy Back result from d_c[0]
    leaq    h_c(%rip), %rdi
    movq    d_c(%rip), %rsi
    movq    $4, %rdx                 # Just 4 bytes (one float)
    call    cuMemcpyDtoH_v2@PLT

    # 7. Print Result (Expected: 42.0)
    leaq    fmt_res(%rip), %rdi
    cvtss2sd h_c(%rip), %xmm0
    movb    $1, %al
    call    printf@PLT

    # Exit
    xorq    %rdi, %rdi
    movq    $exit_group, %rax
    syscall

.section .rodata
kernel_bin:  .incbin "kernel.cubin"
kernel_name: .asciz  "gpu_write"
fmt_res:     .asciz  "Value at d_c[0]: %.1f\n"

.section .data
.align 8
n_val:      .long   1
h_module:   .quad   0
h_func:     .quad   0
d_c:        .quad   0
param_a:    .quad   0
param_b:    .quad   0
param_c:    .quad   0
param_n:    .quad   0
kernel_params: .quad param_a, param_b, param_c, param_n
h_c:        .float  0.0

.section .note.GNU-stack,"",@progbits

