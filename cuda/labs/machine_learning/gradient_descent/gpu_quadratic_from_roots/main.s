# -----------------------------------------------------------------------------
# HOST PROGRAM: Quadratic Equation Solver Orchestrator (PIE‑safe)
# Uses CUDA Driver API (libcuda.so)
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# CPU‑SIDE RECONSTRUCTION
# The GPU always learns a *normalized* quadratic with leading coefficient a = 1
# for numerical stability. The original leading coefficient (“scale”) is stored
# separately in the result buffer. The host reconstructs the full quadratic as:
#
#     A = scale
#     B = b_norm * scale
#     C = c_norm * scale
#
# The host does not validate or correct what the optimizer produced. If the GPU
# converges well, A, B, C describe the intended quadratic. If the optimizer
# overshoots, drifts, or diverges, that behavior is visible directly in these
# reconstructed coefficients.
# -----------------------------------------------------------------------------

    .section .rodata
    .align 16

kernel_bin:  .incbin "kernel.cubin"
learn_name:  .asciz "learnQuadratic"
solve_name:  .asciz "solveQuadratic"
out_fmt: .asciz "Learned: %.0fx² %+.0fx %+.0f = 0 | Roots: %g %g\n"

    .section .data
    .align 8
h_inputs:     .float 3.0, 7.0, 40.0

h_results:    .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

d_ptr:        .quad 0
h_module:     .quad 0
h_learn_func: .quad 0
h_solve_func: .quad 0
args_list:    .quad 0

    .section .text
    .globl _start
    .type _start, @function

    .extern cuInit
    .extern cuDeviceGet
    .extern cuCtxCreate_v2
    .extern cuCtxPushCurrent_v2
    .extern cuModuleLoadData
    .extern cuModuleGetFunction
    .extern cuMemAlloc_v2
    .extern cuMemcpyHtoD_v2
    .extern cuLaunchKernel
    .extern cuCtxSynchronize
    .extern cuMemcpyDtoH_v2
    .extern printf

_start:
    andq $-16, %rsp
    subq $16, %rsp

    xorl %edi, %edi
    call cuInit

    movq %rsp, %rdi
    xorl %esi, %esi
    call cuDeviceGet
    movl (%rsp), %edx

    movq %rsp, %rdi
    xorl %esi, %esi
    call cuCtxCreate_v2

    movq (%rsp), %rdi
    call cuCtxPushCurrent_v2

    leaq h_module(%rip), %rdi
    leaq kernel_bin(%rip), %rsi
    call cuModuleLoadData

    leaq h_learn_func(%rip), %rdi
    movq h_module(%rip), %rsi
    leaq learn_name(%rip), %rdx
    call cuModuleGetFunction

    leaq h_solve_func(%rip), %rdi
    movq h_module(%rip), %rsi
    leaq solve_name(%rip), %rdx
    call cuModuleGetFunction

    leaq d_ptr(%rip), %rdi
    movq $64, %rsi
    call cuMemAlloc_v2

    movq d_ptr(%rip), %rdi
    addq $32, %rdi
    leaq h_inputs(%rip), %rsi
    movq $12, %rdx
    call cuMemcpyHtoD_v2

    leaq d_ptr(%rip), %rax
    movq %rax, args_list(%rip)

    movq h_learn_func(%rip), %rdi
    movl $1, %esi
    movl $1, %edx
    movl $1, %ecx
    movl $32, %r8d
    movl $1, %r9d

    subq $8, %rsp
    pushq $0
    leaq args_list(%rip), %rax
    pushq %rax
    pushq $0
    pushq $0
    pushq $1
    call cuLaunchKernel
    addq $48, %rsp

    call cuCtxSynchronize

    movq h_solve_func(%rip), %rdi
    movl $1, %esi
    movl $1, %edx
    movl $1, %ecx
    movl $1, %r8d
    movl $1, %r9d

    subq $8, %rsp
    pushq $0
    leaq args_list(%rip), %rax
    pushq %rax
    pushq $0
    pushq $0
    pushq $1
    call cuLaunchKernel
    addq $48, %rsp

    call cuCtxSynchronize

    leaq h_results(%rip), %rdi
    movq d_ptr(%rip), %rsi
    movq $32, %rdx
    call cuMemcpyDtoH_v2

        # ------------------------ Reconstruct true A,B,C ------------------------

    # Load normalized b, c
    movss h_results(%rip),    %xmm1      # b_norm
    movss h_results+4(%rip),  %xmm2      # c_norm

    # Load scale (true A)
    movss h_results+20(%rip), %xmm3      # scale

    # A_f = scale
    movss %xmm3, %xmm0                    # A_f

    # B_f = b_norm * scale
    mulss %xmm3, %xmm1                    # B_f

    # C_f = c_norm * scale
    mulss %xmm3, %xmm2                    # C_f

    # Convert A,B,C to double in xmm0–xmm2 for printf
    cvtss2sd %xmm0, %xmm0                 # A
    cvtss2sd %xmm1, %xmm1                 # B
    cvtss2sd %xmm2, %xmm2                 # C

    # Roots (still from normalized quadratic)
    cvtss2sd 8+h_results(%rip),  %xmm3    # x1
    cvtss2sd 12+h_results(%rip), %xmm4    # x2

    # ------------------------ Pretty printf ------------------------

    leaq out_fmt(%rip), %rdi
    movl $5, %eax
    call printf

    xorq %rdi, %rdi
    movq $231, %rax
    syscall

    .size _start, . - _start
    .section .note.GNU-stack,"",@progbits
