# name        : main.s
# description : Loop-based harness for avx_addarrays

.section .data
    .align 32
    array_a:   .float 1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8
    array_b:   .float 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0
    
    .align 32
    result:    .zero 32

    fmt_header: .asciz "AVX Results:\n"
    fmt_val:    .asciz "  [%d] = %f\n"
    msg_done:   .asciz "Done.\n"

.section .text
.extern printf
.globl _start

_start:
    # 1. Align stack and save registers we'll use for the loop
    # We use rbx and r12 because they are "callee-saved" (printf won't trash them)
    push %rbp
    push %rbx
    push %r12
    and $-16, %rsp

    # 2. Perform the AVX Math
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    call avx_addarrays

    # 3. Print Header
    lea fmt_header(%rip), %rdi
    xor %eax, %eax
    call printf

    # 4. Print Loop
    xor %rbx, %rbx              # rbx = loop index (0 to 7)
    lea result(%rip), %r12      # r12 = pointer to data

print_loop:
    cmp $8, %rbx
    je end_print

    # Prepare printf: printf(fmt_val, index, value)
    lea fmt_val(%rip), %rdi     # Arg 1: Format string
    mov %rbx, %rsi              # Arg 2: Current index (integer)
    
    # Arg 3: The float (must be converted to double for %f)
    # We use the index rbx to offset: result + (rbx * 4 bytes)
    cvtss2sd (%r12, %rbx, 4), %xmm0 
    
    mov $1, %al                 # 1 float argument in xmm0
    call printf

    inc %rbx
    jmp print_loop

end_print:
    lea msg_done(%rip), %rdi
    xor %eax, %eax
    call printf

    # 5. Exit
    mov $60, %rax
    xor %rdi, %rdi
    syscall

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
