# name        : main.s
# description : Harness for AVX2 Integer Add

.section .data
    .align 32
    array_a:   .long 100, 200, 300, 400, 500, 600, 700, 800
    array_b:   .long 1, 2, 3, 4, 5, 6, 7, 8
    
    .align 32
    result:    .zero 32

    fmt_header: .asciz "AVX2 Integer Results:\n"
    fmt_val:    .asciz "  [%d] = %d\n"
    msg_done:   .asciz "Done.\n"

.section .text
.extern printf
.globl _start

_start:
    # 1. Align stack and save registers
    push %rbp
    push %rbx
    push %r12
    and $-16, %rsp

    # 2. Call AVX2 Function
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    call avx2_addarrays

    # 3. Print Header
    lea fmt_header(%rip), %rdi
    xor %eax, %eax
    call printf

    # 4. Print Loop (8 integers)
    xor %rbx, %rbx              # Index = 0
    lea result(%rip), %r12      # Pointer to results

print_loop:
    cmp $8, %rbx
    je end_program

    lea fmt_val(%rip), %rdi     # Format string
    mov %rbx, %rsi              # Arg 2: Index (%d)
    mov (%r12, %rbx, 4), %edx   # Arg 3: Value (%d)
    
    xor %eax, %eax              # 0 float args
    call printf

    inc %rbx
    jmp print_loop

end_program:
    lea msg_done(%rip), %rdi
    xor %eax, %eax
    call printf

    mov $60, %rax
    xor %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
