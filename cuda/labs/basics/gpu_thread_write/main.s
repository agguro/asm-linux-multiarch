# -----------------------------------------------------------------------------
# x86_64 CUDA Thread ID Printer
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
    subq    $512, %rsp      # Space for context, dev, and loop counter

    # 1. Init CUDA
    xorl    %edi, %edi; call cuInit@PLT
    leaq    16(%rsp), %rdi; xorl %esi, %esi; call cuDeviceGet@PLT
    leaq    24(%rsp), %rdi; xorl %esi, %esi; movl 16(%rsp), %edx; call cuCtxCreate_v2@PLT

    # 2. Load Module/Func
    leaq    h_module(%rip), %rdi; leaq kernel_bin(%rip), %rsi; call cuModuleLoadData@PLT
    leaq    h_func(%rip), %rdi; movq h_module(%rip), %rsi; leaq kernel_name(%rip), %rdx; call cuModuleGetFunction@PLT

    # 3. Allocate 1024 bytes (256 floats * 4)
    movq    $1024, %rsi
    leaq    d_c(%rip), %rdi; call cuMemAlloc_v2@PLT

    # 4. Params
    movq    d_c(%rip), %rax; movq %rax, param_c(%rip)
    leaq    n_val(%rip), %rax; movq %rax, param_n(%rip)

    # 5. Launch 256 Threads (1 block, 256 threads)
    subq    $80, %rsp
    movq    $1, 0(%rsp)              # blockDimZ
    movq    $0, 8(%rsp)              # sharedMem
    movq    $0, 16(%rsp)             # hStream
    leaq    kernel_params(%rip), %rax
    movq    %rax, 24(%rsp)           # kernelParams
    movq    $0, 32(%rsp)             # extra

    movq    h_func(%rip), %rdi       
    movl    $1, %esi                 # gridDimX
    movl    $1, %edx                 # gridDimY
    movl    $1, %ecx                 # gridDimZ
    movl    $256, %r8d               # blockDimX (256 threads)
    movl    $1, %r9d                 # blockDimY
    call    cuLaunchKernel@PLT
    addq    $80, %rsp

    call    cuCtxSynchronize@PLT

    # 6. Copy back 256 floats
    leaq    h_c(%rip), %rdi
    movq    d_c(%rip), %rsi
    movq    $1024, %rdx
    call    cuMemcpyDtoH_v2@PLT

    # 7. PRINT LOOP (Print 256 results)
    movq    $0, 40(%rsp)             # Loop index i = 0
.Lprint_loop:
    cmpq    $256, 40(%rsp)           # if i == 256, exit
    je      .Ldone

    # Prepare printf
    leaq    fmt_res(%rip), %rdi      # Arg 1: Format string
    movq    40(%rsp), %rsi           # Arg 2: The integer index i
    
    # Get h_c[i]
    leaq    h_c(%rip), %rax
    movq    40(%rsp), %rdx
    movss   (%rax, %rdx, 4), %xmm0   # Load float from h_c + (i * 4)
    cvtss2sd %xmm0, %xmm0            # Convert to double for printf
    movb    $1, %al                  # 1 vector register used
    call    printf@PLT

    incq    40(%rsp)                 # i++
    jmp     .Lprint_loop

.Ldone:
    xorq    %rdi, %rdi
    movq    $exit_group, %rax
    syscall

.section .rodata
kernel_bin:  .incbin "kernel.cubin"
kernel_name: .asciz  "gpu_thread_write"
fmt_res:     .asciz  "Thread %ld wrote: %.1f\n"

.section .data
.align 8
n_val:      .long   256
h_module:   .quad   0
h_func:     .quad   0
d_c:        .quad   0
param_a:    .quad   0
param_b:    .quad   0
param_c:    .quad   0
param_n:    .quad   0
kernel_params: .quad param_a, param_b, param_c, param_n

.align 16
h_c:        .fill   256, 4, 0        # Space for 256 floats

.section .note.GNU-stack,"",@progbits
