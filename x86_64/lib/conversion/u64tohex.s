/* **************************************************************************
 * Name         : u64tohex.s
 * Assemble     : as --64 u64tohex.s -o u64tohex.o
 * Description  : Converts a 64-bit unsigned integer to a Hex string.
 *
 * Input        : RDI = value, RSI = start of buffer, RDX = buffer len
 * Output       : RAX = 0 (success) or 1 (overflow)
 * Registers    : RDI = unchanged
 * RSI = pointer to start of hex digits (including 0x)
 * RDX = actual length (including 0x)
 *
 * Strategy:
 * This function fills the buffer from right to left. By starting at the end 
 * of the buffer and moving backwards, the digits naturally end up in the 
 * correct order without requiring a separate "string reverse" pass. It then
 * prepends the "0x" prefix if space permits.
 * ************************************************************************** */

.section .text
.globl u64tohex
.type u64tohex, @function

u64tohex:
    pushq   %rbp                
    movq    %rsp, %rbp      

    leaq    (%rsi, %rdx), %rcx      # End of buffer
    movq    %rcx, %r9               # Save for length math
    movq    %rdi, %rax              

    # --- Main Hex Loop ---
1:
    decq    %rcx
    cmpq    %rsi, %rcx              
    jl      3f                      # Overflow: buffer too small

    movq    %rax, %r8
    andq    $0xF, %r8               # Isolate last 4 bits (one hex digit)

    cmpb    $10, %r8b
    jl      2f                      # If 0-9
    addb    $('A' - 10), %r8b       # If A-F
    jmp     4f                      

2:
    addb    $'0', %r8b              

4:
    movb    %r8b, (%rcx)            
    shrq    $4, %rax                # Shift to next nibble (4 bits)
    jnz     1b                      # Continue if value remains

    # --- Add "0x" Prefix ---
    subq    $2, %rcx                # Need 2 bytes for '0' and 'x'
    cmpq    %rsi, %rcx
    jl      3f                      # Trigger overflow if no room for prefix

    movb    $'0', (%rcx)            # Store prefix '0'
    movb    $'x', 1(%rcx)           # Store prefix 'x'

    # --- Success Exit ---
    movq    %r9, %rdx
    subq    %rcx, %rdx              # Calculate final length
    movq    %rcx, %rsi              # Update RSI to start of "0x"
    xorq    %rax, %rax              # Return 0 (success)
    popq    %rbp                    
    ret

3:  # --- Error Exit ---
    movq    $1, %rax                # Return 1 (Overflow)
    popq    %rbp                    
    ret

.size u64tohex, .-u64tohex
.section .note.GNU-stack,"",@progbits
