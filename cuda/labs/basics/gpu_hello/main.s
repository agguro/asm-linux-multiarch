# -----------------------------------------------------------------------------
# HOST PROGRAM: CUDA Hello World (PIE + GOT + Alignment)
# -----------------------------------------------------------------------------

.nolist
    .include "unistd.inc"
.list

.section .text
.globl _start

_start:
    # --- 1. Robust ABI Stack Alignment ---
    pushq   %rbp            # Save frame pointer
    movq    %rsp, %rbp      # Set up new frame pointer
    andq    $-16, %rsp      # Force 16-byte alignment
    subq    $128, %rsp      # Reserve generous scratch space

    # --- 2. Initialize CUDA ---
    xorl    %edi, %edi      
    call    cuInit@PLT      # Using PLT for the shared library
    testq   %rax, %rax
    jnz     error_exit

    # --- 3. Get Device & Context ---
    leaq    16(%rsp), %rdi  # Use stack scratch space for device handle
    xorl    %esi, %esi      # device 0
    call    cuDeviceGet@PLT
    
    leaq    24(%rsp), %rdi  # Use stack scratch space for context handle
    xorl    %esi, %esi      
    movl    16(%rsp), %edx  # Load the device handle we just got
    call    cuCtxCreate_v2@PLT
    
    movq    24(%rsp), %rdi  # Load the context handle
    call    cuCtxPushCurrent_v2@PLT

    # --- 4. Load GPU Binary (Cubin) ---
    leaq    h_module(%rip), %rdi
    leaq    kernel_bin(%rip), %rsi
    call    cuModuleLoadData@PLT
    testq   %rax, %rax
    jnz     error_exit

    # --- 5. Get Kernel Function ---
    leaq    h_func(%rip), %rdi
    movq    h_module(%rip), %rsi
    leaq    kernel_name(%rip), %rdx
    call    cuModuleGetFunction@PLT

    # --- 6. Allocate GPU Memory ---
    leaq    d_ptr(%rip), %rdi
    movq    $20, %rsi
    call    cuMemAlloc_v2@PLT

# --- 7. Prepare Kernel Arguments ---
    # We need: args_list[0] = &d_ptr
    # The driver will dereference args_list[0] to find the GPU pointer.
    leaq    d_ptr(%rip), %rax
    movq    %rax, args_list(%rip) 

    # --- 8. Launch Kernel (Corrected Stack) ---
    # We need 11 arguments. 1-6 in registers, 7-11 on stack.
    # We use 16-byte alignment (subq $48: 5 args * 8 bytes + 8 padding)
    
    subq    $48, %rsp           
    movq    $0, 32(%rsp)        # 11. extra (NULL)
    leaq    args_list(%rip), %rax
    movq    %rax, 24(%rsp)      # 10. kernelParams (This is the void**)
    movq    $0, 16(%rsp)        # 9.  hStream
    movq    $0, 8(%rsp)         # 8.  sharedMemBytes
    movq    $1, (%rsp)          # 7.  blockDimZ

    movq    h_func(%rip), %rdi  # 1. f
    movl    $1, %esi            # 2. gridDimX
    movl    $1, %edx            # 3. gridDimY
    movl    $1, %ecx            # 4. gridDimZ
    movl    $5, %r8d            # 5. blockDimX
    movl    $1, %r9d            # 6. blockDimY
    
    call    cuLaunchKernel@PLT
    addq    $48, %rsp
    
    call    cuCtxSynchronize@PLT

    # --- 9. Copy Results Back ---
    leaq    h_results(%rip), %rdi
    movq    d_ptr(%rip), %rsi
    movq    $20, %rdx
    call    cuMemcpyDtoH_v2@PLT

    # --- 10. Display Results ---
    xorq    %rbx, %rbx
print_loop:
    movq    $1, %rdi
    leaq    msg_prefix(%rip), %rsi
    call    print_stringz@PLT

    leaq    h_results(%rip), %rax
    movl    (%rax, %rbx, 4), %edi
    
    # Simple u64toa call (Assume it preserves RBX)
    subq    $32, %rsp
    movq    %rsp, %rsi
    movq    $31, %rdx
    call    u64toa@PLT
    
    movq    %rdx, %rdx
    movq    %rsi, %rsi
    movq    $write, %rax            # sys_write
    movq    $1, %rdi            # stdout
    syscall
    addq    $32, %rsp

    movq    $1, %rdi
    leaq    msg_suffix(%rip), %rsi
    call    print_stringz@PLT
    
    incq    %rbx
    cmpq    $5, %rbx
    jl      print_loop

    # --- 11. Exit ---
    xorq    %rdi, %rdi
    movq    $exit_group, %rax
    syscall

error_exit:
    movq    %rax, %rdi          # Exit with the error code in RAX
    movq    $exit, %rax
    syscall

.size _start, . - _start

.section .data
.align 16
kernel_bin:  .incbin "kernel.cubin"
kernel_name: .asciz  "gpu_hello"
msg_prefix:  .asciz  "Hello from CPU! GPU thread "
msg_suffix:  .asciz  ".\n"

.align 8
h_module:    .quad 0
h_func:      .quad 0
d_ptr:       .quad 0        
args_list:   .quad 0        
h_results:   .long -1, -1, -1, -1, -1



.section .note.GNU-stack,"",@progbits
