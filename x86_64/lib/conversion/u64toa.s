/* **************************************************************************
 * Name         : u64toa.s
 * Assemble     : as --64 u64toa.s -o u64toa.o
 * Description  : Converts a 64-bit unsigned integer to a decimal string.
 *
 * Input        : RDI = value, RSI = start of buffer, RDX = buffer len
 * Output       : RAX = 0 (success) or 1 (overflow)
 * Registers    : RDI = unchanged
 * RSI = pointer to start of digits
 * RDX = actual length
 *
 * Strategy:
 * This function performs division by 10 using a reciprocal multiplication
 * (Magic Number: 0xCCCCCCCCCCCCCCCD). This is significantly faster than
 * the hardware 'div' instruction. The buffer is filled from right to left.
 * ************************************************************************** */

.section .text
.globl u64toa
.type u64toa, @function

u64toa:
    # --- Prologue ---
    pushq   %rbp                    # Save caller's frame pointer
    movq    %rsp, %rbp              # Establish stack frame

    # --- Setup ---
    leaq    (%rsi, %rdx), %rcx      # %rcx = End of buffer (writing backwards)
    movq    %rcx, %r9               # Save end address for length math
    movq    %rdi, %rax              # %rax = working copy of the value
    movabsq $0xCCCCCCCCCCCCCCCD, %r8 # Magic number for division by 10

    # --- Conversion Loop ---
1:
    decq    %rcx
    cmpq    %rsi, %rcx              # Buffer overflow check
    jl      2f                      # If %rcx < start, jump to error



    movq    %rax, %r11              # %r11 = temporary copy for modulo
    mulq    %r8                     # High 64 bits of result in %rdx
    shrq    $3, %rdx                # %rdx = quotient (value / 10)
    
    # Modulo: %r11 = value - (quotient * 10)
    leaq    (%rdx, %rdx, 4), %r10   # %r10 = quotient * 5
    shlq    $1, %r10                # %r10 = quotient * 10
    subq    %r10, %r11              # %r11 = digit (0-9)
    
    # Convert to ASCII and store
    addb    $'0', %r11b
    movb    %r11b, (%rcx)
    
    movq    %rdx, %rax              # Prepare quotient for next iteration
    testq   %rax, %rax              # Is quotient zero?
    jnz     1b                      # If not, loop back

    # --- Success Exit ---
    movq    %r9, %rdx
    subq    %rcx, %rdx              # %rdx = actual length
    movq    %rcx, %rsi              # %rsi = pointer to the first digit
    xorq    %rax, %rax              # Return status 0 (Success)
    
    popq    %rbp                    # Epilogue
    ret

    # --- Error Path ---
2:
    movq    $1, %rax                # Return status 1 (Overflow)
    popq    %rbp                    # Epilogue
    ret

.size u64toa, .-u64toa    
.section .note.GNU-stack,"",@progbits
