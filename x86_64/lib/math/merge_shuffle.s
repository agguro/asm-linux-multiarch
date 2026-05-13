/* 
 ***************************************************************************
 * Name        : merge_shuffle.s
 * Description : A recursive, divide-and-conquer shuffling algorithm.
 * Simulates randomness by interleaving sub-sections of the buffer.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = Pointer to the buffer
 * %rsi = Number of elements in the buffer (N)
 * Output      : None (Buffer is shuffled in-place)
 *
 * Strategy    : Recursively splits the buffer into halves until the base 
 * case (1 element) is reached. During the merge phase, 
 * uses 'rdtsc' as a binary "coin flip" to decide whether to 
 * interleave elements from the left or right sub-arrays, 
 * utilizing the CPU stack for recursion state.
 * **************************************************************************
 */

.section .text
.globl merge_shuffle
.type merge_shuffle, @function

merge_shuffle:
    # --- 1. Base Case: If size (%rsi) <= 1, exit ---
    cmpq    $1, %rsi
    jle     .Ldone                  

    # --- 2. Save Stack Frame & Callee-Saved Regs ---
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %r12                    # Store current Buffer Pointer
    pushq   %r13                    # Store current Size
    pushq   %r14                    # Store Midpoint Offset

    movq    %rdi, %r12              
    movq    %rsi, %r13              

    # Calculate Midpoint Offset
    movq    %r13, %r14
    shrq    $1, %r14                # r14 = Size / 2 (e.g., 26)

    # --- 3. Recurse Left Half (r12 to r12 + r14) ---
    movq    %r12, %rdi              # Start of buffer
    movq    %r14, %rsi              # Left size
    call    merge_shuffle

    # --- 4. Recurse Right Half (r12 + r14 to r12 + r13) ---
    movq    %r12, %rdi
    addq    %r14, %rdi              # rdi = Start + Midpoint
    movq    %r13, %rsi
    subq    %r14, %rsi              # rsi = Total - Left
    call    merge_shuffle

    # --- 5. Merge Phase (Interleave) ---
    # We walk RCX from Size-1 down to 0
    movq    %r13, %rcx              
.Lmerge_loop:
    decq    %rcx                    # rcx is now the current index (0..51)
    
    rdtsc                           # Get random bit
    testb   $1, %al
    jz      .Lskip_swap

    # WE DO NOT USE (%r12, %rax) HERE.
    # We calculate the addresses explicitly to see them in GDB.
    
    # Target 1: Current loop index
    leaq    (%r12, %rcx), %r8       # r8 = address of current element
    
    # Target 2: The Midpoint
    leaq    (%r12, %r14), %r9       # r9 = address of midpoint element

    # Perform the Swap using registers
    movb    (%r8), %al
    movb    (%r9), %bl
    movb    %bl, (%r8)
    movb    %al, (%r9)

.Lskip_swap:
    testq   %rcx, %rcx              # Manual loop to ensure rcx stays positive
    jnz     .Lmerge_loop

    # --- 6. Cleanup ---
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbp
.Ldone:
    ret

.size merge_shuffle, .-merge_shuffle
.section .note.GNU-stack,"",@progbits
