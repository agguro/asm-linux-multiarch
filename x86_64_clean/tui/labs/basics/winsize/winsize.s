/*
 **************************************************************************
 * Name          : winsize.s
 * Description   : Displays terminal dimensions (Rows, Cols, Pixels).
 *
 * Build Sequence:
 * 1. Assemble: as --64 -g -I ../../../include winsize.s -o winsize.o
 *              as --64 -g -I ../../../lib strlen.s strlen.o
 *              as --64 -g -I ../../../lib print_stringz.s print_stringz.o
 *              as --64 -g -I ../../../lib u64toa.s u64toa.o
 *
 * 2. Link:     ld -m elf_x86_64 -pie -o winsize winsize.o \
 *              strlen.o print_stringz.o u64toa.o
 *
 * Strategy:
 * 1. Use 'ioctl' with TIOCGWINSZ to populate the winsize structure.
 * 2. Iterate through the structure's 4 words (rows, cols, xpixel, ypixel).
 * 3. Use the high-performance 'u64toa' library to convert numbers to strings.
 * 4. Print results using the ABI-transparent 'print_stringz' library.
 * **************************************************************************
 */
 
.nolist
    .include "unistd.inc"
.list

# --- Local Definitions (Replacing termios.inc) ---
.equ TIOCGWINSZ, 0x5413             # Kernel constant to "Get Window Size"
.equ WINSIZE_SIZE, 8                # Structure is 4 x 16-bit words

.extern print_stringz
.extern u64toa

.section .bss
    .align 16
    .Lconv_buf:     .skip 20        # Buffer for u64toa conversion
    .lcomm .Lwinsize_struct, WINSIZE_SIZE 

.section .rodata
    .Llabels:
        .ascii "rows    : \0"
        .ascii "columns : \0"
        .ascii "xpixels : \0"
        .ascii "ypixels : \0"
    .equ ITEM_SIZE, 11              # Bytes per null-terminated label string
    .equ ITEM_COUNT, 4

    .Lcrlf: .ascii "\n\0"

.section .text
    .globl _start

_start:
    # 1. Get terminal size via ioctl
    # sys_ioctl(fd: stdout, request: TIOCGWINSZ, arg: &winsize_struct)
    movl    $stdout, %edi
    movl    $TIOCGWINSZ, %esi
    leaq    .Lwinsize_struct(%rip), %rdx
    movl    $ioctl, %eax
    syscall

    # 2. Initialize Loop Pointers
    # Using callee-saved registers to maintain stability across library calls
    leaq    .Llabels(%rip), %r13    # R13 = Current Label pointer
    leaq    .Lwinsize_struct(%rip), %r14 # R14 = Current Struct data pointer
    movq    $ITEM_COUNT, %r15       # R15 = Counter (4 items)

.LnextVariable:
    # --- Step 1: Print the Label ---
    movl    $stdout, %edi
    movq    %r13, %rsi
    call    print_stringz           # ABI-transparent print

    # --- Step 2: High-Performance Conversion (u64toa) ---
    # Convert 16-bit word to decimal string using magic numbers
    movzwl  (%r14), %edi            # Load 16-bit value into RDI
    leaq    .Lconv_buf(%rip), %rsi  # Destination buffer
    movq    $20, %rdx               # Buffer length
    call    u64toa                  # Returns RSI = start of digits, RDX = length
    
    # --- Step 3: Print the Digits ---
    # u64toa optimizes by returning the exact RDX and RSI needed for sys_write
    movl    $stdout, %edi           # File descriptor
    movl    $write, %eax            # sys_write
    syscall

    # --- Step 4: Print Newline ---
    movl    $stdout, %edi
    leaq    .Lcrlf(%rip), %rsi
    call    print_stringz           #
    
    # --- Step 5: Increment and Loop ---
    addq    $2, %r14                # Move to next 16-bit word in winsize struct
    addq    $ITEM_SIZE, %r13        # Move to next null-terminated label
    decq    %r15
    jnz     .LnextVariable

    # Exit
    movl    $exit, %eax
    xorl    %edi, %edi
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
