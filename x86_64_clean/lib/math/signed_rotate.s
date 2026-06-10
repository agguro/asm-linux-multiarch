/* **************************************************************************
 * Name         : signed_rotate.s
 * Assemble     : as --64 signed_rotate.s -o signed_rotate.o
 * Description  : Specialized circular rotation for arbitrary bit-windows.
 *
 * API          : srol(value, len, count), sror(value, len, count)
 * Input        : %rdi = Value, %rsi = Bitlength (L), %rdx = Count (N)
 * Output       : %rax = Rotated Result
 *
 * Strategy:
 * This library implements "Signed" rotation where the Most Significant Bit 
 * (MSB) of the defined length remains fixed as a "Sign Bit." The remaining 
 * (L-1) bits are rotated. It includes a "Shortest Path" optimization: 
 * if rotating 10 times in a 12-bit window, it will automatically perform 
 * 2 rotations in the opposite direction for maximum efficiency.
 * ************************************************************************** */

.section .text

.globl srol
.type srol, @function
srol:
    xorl    %r10d, %r10d            # Direction 0 = Left
    jmp     _rotate_sig_backend

.globl sror
.type sror, @function
sror:
    movl    $1, %r10d               # Direction 1 = Right
    jmp     _rotate_sig_backend

.type _rotate_sig_backend, @function
_rotate_sig_backend:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13

    # 1. Window Width (W = L - 1)
    cmpq    $2, %rsi
    jl      .Ldone_exit
    movq    %rsi, %r8
    decq    %r8                     # %r8 = W (Data bits excluding sign)

    # 2. Normalize Count (N % W)
    movq    %rdx, %rax              # Move Count to rax for division
    movq    %r10, %r12              # Save direction in r12
    xorq    %rdx, %rdx              # Clear rdx for divq
    divq    %r8                     # rax = quotient, rdx = remainder
    
    movq    %rdx, %rbx              # %rbx = Normalized Count
    testq   %rbx, %rbx
    jz      .Ldone_exit             # If count is 0, exit early

    # 3. Shortest Path Optimization
    movq    %r8, %rax
    shrq    $1, %rax                # rax = W / 2
    cmpq    %rax, %rbx
    jbe     .Lprepare_masks         # If count <= W/2, proceed normally

    # Flip Logic: N_new = W - N_old
    subq    %rbx, %r8
    movq    %r8, %rbx               # rbx = Flipped Count
    xorq    $1, %r12                # Flip Direction Flag
    
    # Restore W in %r8
    movq    %rsi, %r8
    decq    %r8



.Lprepare_masks:
    # 4. Create Isolation Masks
    movq    $1, %rcx
    movb    %r8b, %cl               # cl = W
    shlq    %cl, %rcx               # rcx = 1 << W
    movq    %rcx, %r9               # r9 = Sign Bit Mask
    
    decq    %rcx                    # rcx = (1 << W) - 1
    movq    %rcx, %r13              # r13 = Body Mask

    # 5. Isolate Components
    movq    %rdi, %rax
    andq    %r13, %rax              # %rax = The Body (bits to rotate)
    
    movq    %rdi, %r11
    andq    %r9, %r11               # %r11 = The Fixed Sign Bit

    # 6. Directional Trigger
    shrq    $1, %r12
    jc      .Lright_loop

# --- Left Bridge (Rotation within window r8) ---
.Lleft_loop:
    movq    %rax, %r10              # Copy body
    movq    %r8, %rcx
    decq    %rcx                    # rcx = W - 1
    shrq    %cl, %r10               # r10 Bit 0 = MSB of window
    
    shlq    $1, %rax                # Shift Left
    andq    %r13, %rax              # Mask to window size
    
    andq    $1, %r10                # Isolate the bit to wrap
    orq     %r10, %rax              # Wrap MSB -> LSB
    
    decq    %rbx
    jnz     .Lleft_loop
    jmp     .Lfinalize

# --- Right Bridge ---
.Lright_loop:
    movq    %rax, %r10
    andq    $1, %r10                # r10 Bit 0 = LSB
    
    shrq    $1, %rax                # Shift Right
    
    movq    %r8, %rcx
    decq    %rcx
    shlq    %cl, %r10               # Move LSB -> MSB of window position
    
    orq     %r10, %rax              # Wrap LSB -> MSB
    
    decq    %rbx
    jnz     .Lright_loop

.Lfinalize:
    orq     %r11, %rax              # Re-attach the fixed Sign bit

.Ldone_exit:
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

.size srol, .-srol
.size sror, .-sror
.section .note.GNU-stack,"",@progbits
