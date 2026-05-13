# name        : main.s (GPR Version)
# description : Harness for gpr_addarrays using 64-bit integers
# target      : x86_64-linux

.equ ARRAY_SIZE, 5              # Total number of integers in the arrays

.section .data
    # For GPR, we use .quad (64-bit integers)
    array_a:    .quad 10, 20, 30, 40, 50
    array_b:    .quad 1, 2, 3, 4, 5

    result:     .zero (ARRAY_SIZE * 8) # 8 bytes per 64-bit integer

    fmt_header: .asciz "GPR Integer Addition Results:\n"
    fmt_val:    .asciz "  Element [%d]: %ld + %ld = %ld\n"
    msg_done:   .asciz "GPR Processing complete.\n"

.section .text
.extern printf
.globl _start

_start:
    # --- 1. Prepare Stack ---
    pushq %rbp
    movq  %rsp, %rbp
    andq  $-16, %rsp            # Align stack for printf

    # --- 2. Call GPR Function ---
    # rdi = dest, rsi = src1, rdx = src2, rcx = n
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    movq $ARRAY_SIZE, %rcx
    call gpr_addarrays          # Your integer GPR function

    # --- 3. Print Output Header ---
    lea fmt_header(%rip), %rdi
    xorl %eax, %eax             # 0 floating point args
    call printf

    # --- 4. Print Results Loop ---
    pushq %rbx                  # Preserve rbx (callee-saved)
    subq  $8, %rsp              # Re-align stack (8 + 8 = 16)
    xorq  %rbx, %rbx            # Index i = 0

print_loop:
    cmpq $ARRAY_SIZE, %rbx
    je end_print

    # Prepare printf: printf(fmt, index, val_a, val_b, res)
    lea fmt_val(%rip), %rdi     # Arg 1: Format string
    movq %rbx, %rsi             # Arg 2: Current index

    # Load 64-bit integers into registers for printf
    # Arg 3: rdx, Arg 4: rcx, Arg 5: r8 (following System V ABI)
    lea array_a(%rip), %rax
    movq (%rax, %rbx, 8), %rdx  # Load from src1

    lea array_b(%rip), %rax
    movq (%rax, %rbx, 8), %rcx  # Load from src2

    lea result(%rip), %rax
    movq (%rax, %rbx, 8), %r8   # Load from result

    xorl %eax, %eax             # 0 floating point args for printf
    call printf

    incq %rbx
    jmp print_loop

end_print:
    addq $8, %rsp               # Cleanup alignment
    popq %rbx                   # Restore rbx

    lea msg_done(%rip), %rdi
    xorl %eax, %eax
    call printf

    # --- 5. Exit ---
    movq %rbp, %rsp
    popq %rbp
    movq $60, %rax              # exit syscall
    xorq %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
