# name        : main.s
# description : Harness for AVX-512 (16 floats)

.section .data
    .align 64               # Mandatory for 512-bit performance
    array_a:   .float 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0
    array_b:   .float 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1
    
    .align 64
    result:    .zero 64     # 16 floats * 4 bytes = 64 bytes

    fmt_header: .asciz "AVX-512 Results:\n"
    fmt_val:    .asciz "  [%d] = %f\n"

.section .text
.extern printf
.globl _start

_start:
    # 1. Align stack
    push %rbp
    push %rbx
    push %r12
    and $-64, %rsp              # Aligning to 64 for AVX-512 is safer

    # 2. Call AVX-512 Function
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    call avx512_addarrays

    # 3. Print Header
    lea fmt_header(%rip), %rdi
    xor %eax, %eax
    call printf

    # 4. Print Loop (16 iterations)
    xor %rbx, %rbx
    lea result(%rip), %r12

print_loop:
    cmp $16, %rbx
    je end_program

    lea fmt_val(%rip), %rdi
    mov %rbx, %rsi
    cvtss2sd (%r12, %rbx, 4), %xmm0 
    mov $1, %al
    call printf

    inc %rbx
    jmp print_loop

end_program:
    mov $60, %rax
    xor %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
