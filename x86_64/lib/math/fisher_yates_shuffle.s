/*
 $**************************************************************************
 * Name        : fisher_yates_shuffle.s
 * Description : Performs an unbiased, linear-time (O(n)) shuffle of a buffer.
 * Ensures every possible permutation of the deck is equally likely.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = Pointer to the buffer (e.g., deck of cards)
 * %rsi = Number of elements in the buffer (N)
 * Output      : None (Buffer is shuffled in-place)
 *
 * Strategy    : Uses the Knuth Shuffle logic: Iterates from the end of the 
 * buffer to the front, swapping the current element 'i' with 
 * a random element 'j' selected from the range [0, i]. 
 * Uses the 'rdtsc' instruction for high-resolution entropy.
 * **************************************************************************
 */

.section .text
.globl fisher_yates_shuffle
.type fisher_yates_shuffle, @function

fisher_yates_shuffle:
    testq   %rsi, %rsi              # Handle 0-length case
    jz      .Ldone
    
    # Initialize buffer with 1..N
    movq    %rsi, %rcx
1:  movb    %cl, -1(%rdi, %rcx)
    loop    1b

    movq    %rsi, %r8               # i = N
.Lloop:
    decq    %r8                     # i-- (goes from N-1 down to 1)
    jz      .Ldone

    # Generate random j in range [0, i]
    rdtsc                           # Get entropy
    shrq    $3, %rax                # Apply empirical shift
    xorq    %rdx, %rdx
    movq    %r8, %rbx
    incq    %rbx                    # Divisor = i + 1
    divq    %rbx                    # RDX = remainder j

    # --- MOV Swap (Performance Optimized) ---
    movb    (%rdi, %r8), %al        # Load buffer[i]
    movb    (%rdi, %rdx), %cl       # Load buffer[j]
    movb    %cl, (%rdi, %r8)        # Store buffer[j] at i
    movb    %al, (%rdi, %rdx)       # Store buffer[i] at j
    
    jmp     .Lloop

.Ldone:
    ret

.size fisher_yates_shuffle, .-fisher_yates_shuffle
.section .note.GNU-stack,"",@progbits
