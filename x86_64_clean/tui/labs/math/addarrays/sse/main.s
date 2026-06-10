# name        : main.s
# description : Loop-based harness for sse_addarrays

.section .data
    .align 16
    array_a:   .float 1.1, 2.2, 3.3, 4.4 
    array_b:   .float 10.0, 20.0, 30.0, 40.0 
    
    .align 16
    result:    .zero 16

    fmt_header: .asciz "SSE Results:\n"
    fmt_val:    .asciz "  [%d] = %f\n"
    msg_done:   .asciz "Done.\n"

.section .text
.extern printf
.globl _start

_start:
    # 1. Stack Alignment and Save Registers
    push %rbp
    push %rbx
    push %r12
    and $-16, %rsp              # Align for libc

    # 2. Call SSE Function
    lea result(%rip), %rdi
    lea array_a(%rip), %rsi
    lea array_b(%rip), %rdx
    call sse_addarrays

    # 3. Print Header
    lea fmt_header(%rip), %rdi
    xor %eax, %eax              # 0 float args for the header string
    call printf

    # 4. Print Loop
    xor %rbx, %rbx              # Index rbx = 0
    lea result(%rip), %r12      # Base pointer r12 = result array

print_loop:
    cmp $4, %rbx                # SSE processes 4 floats
    je end_print

    # Prepare printf: printf(fmt_val, index, value)
    lea fmt_val(%rip), %rdi     # Arg 1: Format string
    mov %rbx, %rsi              # Arg 2: Current index (%d)
    
    # Arg 3: The float (converted to double for %f)
    # result + (index * 4 bytes)
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
