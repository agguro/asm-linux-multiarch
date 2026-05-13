.section .rodata
k_bin:   .incbin "kernel.cubin"
k_name:  .asciz "vecAdd"
.Lfilename:  .asciz "results.csv"
.Lwmode:     .asciz "w"
.Lcsv_header: .asciz "vector A,vector B,result\n"
.Lcsv_fmt:   .asciz "%.1f,%.1f,%.1f\n"

.Lval_three: .float 3.0
.Lval_eight: .float 8.0

.section .text
.globl _start

.equ N, 2097152
.equ SIZE_FLOAT, 4
.equ SIZE_ARRAY, N * SIZE_FLOAT
.equ BLOCK_SIZE, 256
.equ GRID_X, (N + BLOCK_SIZE - 1) / BLOCK_SIZE
.equ LAST_START, N - 10

_start:
    pushq   %rbp
    movq    %rsp, %rbp
    andq    $-16, %rsp
    subq    $256, %rsp

    # 1. Init
    xorl    %edi, %edi; call cuInit@PLT
    leaq    16(%rsp), %rdi; xorl %esi, %esi; call cuDeviceGet@PLT
    leaq    24(%rsp), %rdi; xorl %esi, %esi; movl 16(%rsp), %edx; call cuCtxCreate_v2@PLT

    # 2. Module
    leaq    32(%rsp), %rdi; leaq k_bin(%rip), %rsi; call cuModuleLoadData@PLT
    leaq    40(%rsp), %rdi; movq 32(%rsp), %rsi; leaq k_name(%rip), %rdx; call cuModuleGetFunction@PLT

    # 3. Pinned Allocation (Result Buffer)
    # This allocates memory visible to both CPU and GPU
    leaq    48(%rsp), %rdi   # h_ptr_c
    movl    $SIZE_ARRAY, %esi      # size (N floats * 4 bytes)
    movl    $0, %edx         # flags
    call    cuMemAllocHost_v2@PLT

    # Get the Device Pointer for that pinned memory
    leaq    56(%rsp), %rdi   # d_ptr_c
    movq    48(%rsp), %rsi   # h_ptr_c
    movl    $0, %edx
    call    cuMemHostGetDevicePointer_v2@PLT

    # create and initialize two input vectors a and b (N floats each)
    leaq    64(%rsp), %rdi   # h_ptr_a
    movl    $SIZE_ARRAY, %esi
    movl    $0, %edx
    call    cuMemAllocHost_v2@PLT
    leaq    72(%rsp), %rdi   # d_ptr_a
    movq    64(%rsp), %rsi
    movl    $0, %edx
    call    cuMemHostGetDevicePointer_v2@PLT

    leaq    80(%rsp), %rdi   # h_ptr_b
    movl    $SIZE_ARRAY, %esi
    movl    $0, %edx
    call    cuMemAllocHost_v2@PLT
    leaq    88(%rsp), %rdi   # d_ptr_b
    movq    80(%rsp), %rsi
    movl    $0, %edx
    call    cuMemHostGetDevicePointer_v2@PLT

    # initialize host values (a[i] = i / 7 + 3.0, b[i] = i % 9 + 8.0)
    movq    64(%rsp), %rbx   # a base
    movq    80(%rsp), %r12   # b base
    xorl    %r13d, %r13d     # i=0
.Linit_loop:
    # a[i] = i / 7 + 3.0
    movl    %r13d, %eax
    xorl    %edx, %edx
    movl    $7, %ecx
    divl    %ecx
    cvtsi2ss %eax, %xmm0
    addss   .Lval_three(%rip), %xmm0
    movss   %xmm0, (%rbx, %r13, 4)
    # b[i] = i % 9 + 8.0
    movl    %r13d, %eax
    xorl    %edx, %edx
    movl    $9, %ecx
    divl    %ecx
    cvtsi2ss %edx, %xmm1
    addss   .Lval_eight(%rip), %xmm1
    movss   %xmm1, (%r12, %r13, 4)
    addl    $1, %r13d
    cmpl    $N, %r13d
    jl      .Linit_loop

    # 4. Zero the result memory on host (optional, but for safety)
    # Skip for speed, assume kernel initializes

    # 5. Build Parameter Table
    # Arg0:a, Arg1:b, Arg2:c, Arg3:n
    movq    72(%rsp), %rax; movq %rax, 100(%rsp)    # d_ptr_a
    movq    88(%rsp), %rax; movq %rax, 108(%rsp)    # d_ptr_b
    movq    56(%rsp), %rax; movq %rax, 116(%rsp)    # d_ptr_c
    movq    $N, 124(%rsp)     # n=N

    # kernelParams is an array of pointers to those arguments
    leaq    100(%rsp), %rax; movq %rax, 136(%rsp)
    leaq    108(%rsp), %rax; movq %rax, 144(%rsp)
    leaq    116(%rsp), %rax; movq %rax, 152(%rsp)
    leaq    124(%rsp), %rax; movq %rax, 160(%rsp)

    # 6. Launch
    movq    40(%rsp), %rdi
    movl    $GRID_X, %esi; movl $1, %edx; movl $1, %ecx   # gridDim.x=GRID_X, gridDim.y=1, gridDim.z=1
    movl    $256, %r8d; movl $1, %r9d; movq $1, 0(%rsp) # blockDim.x=256, blockDim.y=1, blockDim.z=1
    movq    $0, 8(%rsp); movq $0, 16(%rsp)
    leaq    136(%rsp), %rax; movq %rax, 24(%rsp)
    movq    $0, 32(%rsp)
    call    cuLaunchKernel@PLT
    
    call    cuCtxSynchronize@PLT

    # 7. Write all results to CSV file
    leaq    .Lfilename(%rip), %rdi
    leaq    .Lwmode(%rip), %rsi
    call    fopen@PLT
    movq    %rax, 96(%rsp)  # file pointer

    # Write header
    movq    96(%rsp), %rdi
    leaq    .Lcsv_header(%rip), %rsi
    xorl    %eax, %eax
    call    fprintf@PLT

    # Write data loop
    movq    64(%rsp), %rbx   # a base
    movq    80(%rsp), %r12   # b base
    movq    48(%rsp), %r13   # c base
    xorl    %r14d, %r14d     # i=0
.Lcsv_loop:
    movq    96(%rsp), %rdi   # file
    leaq    .Lcsv_fmt(%rip), %rsi
    movss   (%rbx, %r14, 4), %xmm0  # a[i]
    cvtss2sd %xmm0, %xmm0
    movss   (%r12, %r14, 4), %xmm1  # b[i]
    cvtss2sd %xmm1, %xmm1
    movss   (%r13, %r14, 4), %xmm2  # c[i]
    cvtss2sd %xmm2, %xmm2
    movb    $3, %al
    call    fprintf@PLT
    addl    $1, %r14d
    cmpl    $N, %r14d
    jl      .Lcsv_loop

    # Close file
    movq    96(%rsp), %rdi
    call    fclose@PLT

    xorq    %rdi, %rdi; movq $231, %rax; syscall    # use exit_group instead of plain exit to terminate all threads


.size _start, . - _start
.section .note.GNU-stack,"",@progbits
