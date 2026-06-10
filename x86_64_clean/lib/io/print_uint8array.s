/*
 ***************************************************************************
 * Name          : print_uint8array.s
 * Description   : Prints an array of 8-bit unsigned integers.
 * Aligns single digits for clean columns and supports items-per-line.
 *
 * ABI           : System V AMD64 (Linux)
 * Input         : %rdi = Buffer pointer (uint8_t*)
 * %rsi = Number of elements
 * %rdx = Items per line (0 for infinite)
 * Output        : Prints to stdout
 * **************************************************************************
 */

.section .rodata
    .Lp_spacer: .byte ' '
    .Lp_eol:    .byte '\n'

.section .bss
    .align 16
    .Lp_conv_buf: .skip 16

.section .text
.globl print_uint8array
.type print_uint8array, @function

print_uint8array:
    pushq   %rbp
    movq    %rsp, %rbp
    # Save callee-saved registers
    pushq   %r12                    # File Descriptor
    pushq   %r13                    # Buffer Pointer
    pushq   %r14                    # Total Elements
    pushq   %r15                    # Items per line limit
    pushq   %rbx                    # Current line counter

    # Move parameters to safe registers
    movq    %rdi, %r12              # FD
    movq    %rsi, %r13              # Pointer
    movq    %rdx, %r14              # Count
    movq    %rcx, %r15              # Per line
    xorq    %rbx, %rbx              # Line counter = 0

.Lloop_start:
    testq   %r14, %r14              # Done?
    jz      .Lall_done

    # --- Step 1: Alignment (Single digit space) ---
    xorq    %rax, %rax
    movb    (%r13), %al
    cmpb    $10, %al
    jge     .Lconvert

    pushq   %rax                    # Save card value
    movq    $1, %rax                # sys_write
    movq    %r12, %rdi              # User's FD
    leaq    .Lp_spacer(%rip), %rsi
    movq    $1, %rdx
    syscall
    popq    %rax

.Lconvert:
    # --- Step 2: Convert ---
    movq    %rax, %rdi              # Value
    leaq    .Lp_conv_buf(%rip), %rsi 
    movq    $16, %rdx
    call    u64toa                  # Returns RSI=ptr, RDX=len

    # --- Step 3: Print Number ---
    movq    $1, %rax                # sys_write
    movq    %r12, %rdi              # User's FD
    # RSI and RDX already set by u64toa
    syscall

    # Print trailing space
    movq    $1, %rax
    movq    %r12, %rdi
    leaq    .Lp_spacer(%rip), %rsi
    movq    $1, %rdx
    syscall

    # --- Step 4: Iteration ---
    incq    %r13                    # Next byte
    decq    %r14                    # One less to go
    
    testq   %r15, %r15              # Line check?
    jz      .Lloop_start
    
    incq    %rbx
    cmpq    %r15, %rbx
    jne     .Lloop_start

    # Newline
    movq    $1, %rax
    movq    %r12, %rdi
    leaq    .Lp_eol(%rip), %rsi
    movq    $1, %rdx
    syscall
    xorq    %rbx, %rbx
    jmp     .Lloop_start

.Lall_done:
    testq   %rbx, %rbx              # Final newline?
    jz      .Lexit
    movq    $1, %rax
    movq    %r12, %rdi
    leaq    .Lp_eol(%rip), %rsi
    movq    $1, %rdx
    syscall

.Lexit:
    popq    %rbx
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbp
    ret

.size print_uint8array, .-print_uint8array
.section .note.GNU-stack,"",@progbits
