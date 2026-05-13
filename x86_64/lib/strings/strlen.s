/* **************************************************************************
 * Name         : strlen.s
 * Assemble     : as --64 strlen.s -o strlen.o
 * Description  : Page-boundary safe Bit-Magic strlen (ABI compliant).
 *
 * Input        : RDI = pointer to string
 * Output       : RAX = length of string
 *
 * Strategy:
 * 1. Byte-align the pointer to an 8-byte boundary to ensure safety.
 * 2. Load 8 bytes at a time into a quadword register.
 * 3. Apply the formula ((x - 0x01...) & ~x & 0x80...) to detect a NULL byte.
 * 4. Use 'bsfq' (Bit Scan Forward) to locate the exact byte within the 
 * register once a NULL is detected.
 * ************************************************************************** */

.section .text
.globl strlen
.type strlen, @function

strlen:
    # --- Prologue ---
    pushq   %rbp            # Save caller's frame pointer
    movq    %rsp, %rbp      # Establish 16-byte alignment
    pushq   %rbx            # Preserve callee-saved RBX
    movq    %rdi, %rax      # Working pointer

    # --- Step 1: Align to 8-byte boundary ---
    # Prevents crossing 4k page boundaries during a quadword load.
1:
    testq   $7, %rax        # Is the pointer 8-byte aligned?
    jz      2f              # If yes, start bit-magic
    cmpb    $0, (%rax)      # Is it a null terminator?
    je      3f              # If yes, exit
    incq    %rax            # Move to next byte
    jmp     1b              

    # --- Step 2: Bit-Magic Initialization ---
2:
    movabsq $0x0101010101010101, %r8  # Mask for least significant bits
    movabsq $0x8080808080808080, %r9  # Mask for most significant bits

    # --- Step 3: Main Loop (Processing 8 bytes at a time) ---


4:
    movq    (%rax), %rdx    # LOAD 8 bytes
    movq    %rdx, %rbx

    subq    %r8, %rbx       # (x - 0x01...)
    notq    %rdx            # ~x
    andq    %rdx, %rbx      # (x - 0x01...) & ~x
    andq    %r9, %rbx       # ... & 0x80...

    jnz     5f              # If non-zero, a NULL was found
    addq    $8, %rax        # Move to next quadword
    jmp     4b              

    # --- Step 4: Identify NULL position ---
5:
    bsfq    %rbx, %rbx      # Find the first '1' bit
    shrq    $3, %rbx        # Bit index to byte offset (bits / 8)
    addq    %rbx, %rax      # Add offset to current pointer

    # --- Step 5: Final Calculation and Exit ---
3:
    subq    %rdi, %rax      # Result = Current Pointer - Start Pointer
    popq    %rbx            # Restore RBX
    popq    %rbp            # Restore RBP
    ret                     

.size strlen, .-strlen
.section .note.GNU-stack,"",@progbits
