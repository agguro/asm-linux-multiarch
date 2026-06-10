# name        : main.s (FPU Version)
# description : Harness for fpu_addarrays using legacy x87 stack
# target      : x86_64-linux

.equ ARRAY_SIZE, 4              # Total number of floats

.section .data
    .align 16
    array_a:    .float 1.5, 2.5, 3.5, 4.5
    array_b:    .float 10.0, 20.0, 30.0, 40.0

    .align 16
    result:     .zero (ARRAY_SIZE * 4)

    fmt_header: .asciz "Legacy FPU (x87) Results:\n"
    fmt_val:    .asciz "  Element [%d]: %.2f + %.2f = %.2f\n"
    msg_done:   .asciz "FPU Processing complete.\n"

.section .text
.extern printf
.globl _start

_start:
    # --- 1. Prepare Stack ---
    pushq %rbp
    movq  %rsp, %rbp
    andq  $-16, %rsp            # Align stack for printf

    # --- 2. Call FPU Function ---
    # rdi = dest, rsi = src1, rdx = src2, rcx = n
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    movq $ARRAY_SIZE, %rcx
    call fpu_addarrays          # Your legacy FPU function

    # --- 3. Print Header ---
    lea fmt_header(%rip), %rdi
    xorl %eax, %eax
    call printf

    # --- 4. Print Results Loop ---
    pushq %rbx                  # Preserve rbx
    subq  $8, %rsp              # Re-align stack (8 + 8 = 16)
    xorq  %rbx, %rbx            # i = 0

print_loop:
    cmpq $ARRAY_SIZE, %rbx
    je end_print

    # Prepare printf: printf(fmt, index, val_a, val_b, res)
    lea fmt_val(%rip), %rdi
    movq %rbx, %rsi

    # IMPORTANT for your course: Even though we used the FPU to calculate,
    # printf (System V ABI) still expects arguments in XMM registers.
    # We must load the results and convert them to doubles.

    lea array_a(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm0
    vcvtss2sd %xmm0, %xmm0, %xmm0 # Arg 3 (double)

    lea array_b(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm1
    vcvtss2sd %xmm1, %xmm1, %xmm1 # Arg 4 (double)

    lea result(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm2
    vcvtss2sd %xmm2, %xmm2, %xmm2 # Arg 5 (double)

    movl $3, %eax               # 3 floating point args
    call printf

    incq %rbx
    jmp print_loop

end_print:
    addq $8, %rsp
    popq %rbx

    lea msg_done(%rip), %rdi
    xorl %eax, %eax
    call printf

    # --- 5. Exit ---
    movq %rbp, %rsp
    popq %rbp
    movq $60, %rax
    xorq %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
