/* **************************************************************************
 * Name         : u64tobin.s
 * Assemble     : as --64 u64tobin.s -o u64tobin.o
 * Description  : Converts a 64-bit integer to a binary bitstring.
 *
 * Input        : %rdi = value
 * %rsi = buffer (minimum 65 bytes)
 * %rdx = mode (0=trim, -1=auto, >0=fixed width)
 * Output       : %rax = pointer to start of string in buffer
 * %rdx = width of the string used
 *
 * Strategy:
 * The function utilizes the 'shlq' and 'adcb' pattern. By shifting the MSB 
 * into the carry flag and adding that flag to the ASCII value of '0', we 
 * generate bits without conditional branching in the main loop.
 * ************************************************************************** */

.section .text
.globl u64tobin
.type u64tobin, @function

u64tobin:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %rcx
    pushq   %rsi            # [rbp-24] Save original buffer start

    # 1. Handle Auto-Detect Mode
    cmpq    $-1, %rdx
    jne     .Lcheck_trim
    lzcntq  %rdi, %rcx      # Get number of leading zeros
    movq    $64, %rdx
    subq    %rcx, %rdx      # Width = 64 - zeros
    jnz     .Lconvert
    movq    $1, %rdx        # If value is 0, width is 1
    jmp     .Lconvert

.Lcheck_trim:
    testq   %rdx, %rdx
    jnz     .Lconvert
    # Mode 0 (trim) logic is processed after conversion loop

.Lconvert:
    pushq   %rdx            # [rbp-32] Store target width
    movq    %rdi, %rax      # Load value
    movq    %rsi, %rdi      # Set write pointer
    movq    $64, %rcx       # Loop counter
    xorq    %rbx, %rbx      # Reset 'first 1' pointer



.Lloop:
    xorl    %r8d, %r8d
    shlq    $1, %rax        # Shift MSB into Carry Flag
    adcb    $'0', %r8b      # ASCII '0' + Carry
    movb    %r8b, (%rdi)    # Store bit
    
    cmpb    $'1', %r8b
    jne     .Lnext
    testq   %rbx, %rbx
    jnz     .Lnext
    movq    %rdi, %rbx      # Capture pointer to first '1'

.Lnext:
    incq    %rdi
    loop    .Lloop
    movb    $0, (%rdi)      # Null terminator

    # --- Result Calculation ---
    popq    %rdx            # Restore target width
    movq    -24(%rbp), %rsi # Restore original buffer start

    testq   %rdx, %rdx
    jz      .Ltrim_logic    # If mode 0, find first '1'

    # Fixed Width: Start = BufferStart + (64 - Width)
    movq    $64, %rax
    subq    %rdx, %rax
    addq    %rsi, %rax      # Calculate final start pointer
    jmp     .Lexit

.Ltrim_logic:
    testq   %rbx, %rbx
    jnz     .Lfound_one
    leaq    63(%rsi), %rax  # Pointer to the last '0'
    movq    $1, %rdx
    jmp     .Lexit

.Lfound_one:
    movq    %rbx, %rax      # Pointer to first '1'
    leaq    64(%rsi), %rdx
    subq    %rbx, %rdx      # Calculate effective width

.Lexit:
    popq    %rsi            # Restore caller's RSI
    popq    %rcx
    popq    %rbx
    popq    %rbp
    ret

.size u64tobin, .-u64tobin 
.section .note.GNU-stack,"",@progbits
