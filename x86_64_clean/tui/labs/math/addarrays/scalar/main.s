# name        : main.s
# description : Final harness for scalar_addarrays with correct stack alignment
# target      : x86_64-linux

.equ ARRAY_SIZE, 4              # Total number of floats in the arrays

.section .data
    .align 16
    array_a:    .float 1.5, 2.5, 3.5, 4.5
    array_b:    .float 10.0, 20.0, 30.0, 40.0

    .align 16
    result:     .zero (ARRAY_SIZE * 4)

    fmt_header: .asciz "Scalar Addition Results:\n"
    fmt_val:    .asciz "  Element [%d]: %.2f + %.2f = %.2f\n"
    msg_done:   .asciz "Processing complete.\n"

.section .text
.extern printf
.globl _start

_start:
    # --- 1. Prepare Stack ---
    pushq %rbp
    movq  %rsp, %rbp
    andq  $-16, %rsp            # Align stack to 16-bytes for C library compatibility

    # --- 2. Call Scalar Function ---
    lea result(%rip), %rdi      # Destination
    lea array_a(%rip), %rsi     # Source 1
    lea array_b(%rip), %rdx     # Source 2
    movq $ARRAY_SIZE, %rcx      # Count
    call scalar_addarrays

    # --- 3. Print Output Header ---
    lea fmt_header(%rip), %rdi
    xorl %eax, %eax
    call printf

    # --- 4. Print Results Loop ---
    pushq %rbx                  # Push #1 (8 bytes)
    subq  $8, %rsp              # Alignment padding (8 bytes) -> Total 16 bytes added
    xorq %rbx, %rbx             # i = 0

print_loop:
    cmpq $ARRAY_SIZE, %rbx
    je end_print

    # Prepare printf: printf(fmt, index, val_a, val_b, res)
    lea fmt_val(%rip), %rdi     # Arg 1: Format string
    movq %rbx, %rsi             # Arg 2: Current index

    # Load and convert values for printf (%f requires doubles)
    #
    lea array_a(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm0
    vcvtss2sd %xmm0, %xmm0, %xmm0 # Arg 3: value from A

    lea array_b(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm1
    vcvtss2sd %xmm1, %xmm1, %xmm1 # Arg 4: value from B

    lea result(%rip), %rax
    vmovss (%rax, %rbx, 4), %xmm2
    vcvtss2sd %xmm2, %xmm2, %xmm2 # Arg 5: result value

    movl $3, %eax               # 3 floating-point arguments in XMM0-2
    call printf

    incq %rbx
    jmp print_loop

end_print:
    addq $8, %rsp               # Remove padding
    popq %rbx                   # Restore rbx

    lea msg_done(%rip), %rdi
    xorl %eax, %eax
    call printf

    # --- 5. Exit ---
    movq %rbp, %rsp
    popq %rbp
    movq $60, %rax              # syscall: exit
    xorq %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
