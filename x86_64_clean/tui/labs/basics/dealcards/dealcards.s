/*
 **************************************************************************
 * Name          : dealcards.s
 * Description   : Card shuffle demonstration (GAS version).
 * Compares Fisher-Yates, Sattolo Cycle, and Merge Shuffle algorithms.
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * /usr/bin/as --64 -g --noexecstack -I ../include \
 * -al=dealcards.lst dealcards.s -o dealcards.o
 *
 * 2. Assemble Library Dependencies:
 * /usr/bin/as --64 -g --noexecstack ../lib/u64toa.s -o u64toa.o
 * /usr/bin/as --64 -g --noexecstack ../lib/strlen.s -o strlen.o
 * /usr/bin/as --64 -g --noexecstack ../lib/print_stringz.s \
 *                  -o print_stringz.o
 * /usr/bin/as --64 -g --noexecstack ../lib/print_uint8array.s \
 °                  -o print_uint8array.o
 * /usr/bin/as --64 -g --noexecstack ../lib/shuffles.s -o shuffles.o
 *
 * 3. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * -o dealcards dealcards.o u64toa.o strlen.o print_stringz.o \
 * print_uint8array.o shuffles.o
 *
 * Strategy:
 * 1. Initialize a 52-byte buffer (deck) with values 1-52 via reset_deck.
 * 2. Display the deck in a 4x13 grid using print_uint8array (RDI=FD, RSI=buf).
 * 3. Execute Fisher-Yates: Linear O(n) shuffle using rdtsc/rdrand entropy.
 * 4. Execute Sattolo Cycle: Variation where no element remains in its place.
 * 5. Execute Merge Shuffle: Recursive divide-and-conquer shuffle approach.
 * 6. Use standardized library calls for all I/O to maintain ABI compliance.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"    
.list

.equ TOTAL_CARDS, 52
.equ CARDS_PER_ROW, 13

.section .rodata
    msg_orig:   .asciz "Original Deck:\n"
    msg_fisher: .asciz "\nFisher-Yates Shuffle:\n"
    msg_sattolo: .asciz "\nSattolo Cycle (Every card moves):\n"
    msg_merge:  .asciz "\nMerge Shuffle (Recursive):\n"

.section .bss
    .align 16
    deck:       .skip TOTAL_CARDS

.section .text
.globl _start
.type _start, @function

# External Library Functions
.extern fisher_yates_shuffle
.extern sattolo_shuffle
.extern merge_shuffle
.extern print_uint8array
.extern print_stringz

_start:
    # --- 1. Show Original Unshuffled Deck ---
    movq    $stdout, %rdi
    leaq    msg_orig(%rip), %rsi
    call    print_stringz
    call    reset_deck
    call    display_deck

    # --- 2. Fisher-Yates Demo ---
    movq    $stdout, %rdi
    leaq    msg_fisher(%rip), %rsi
    call    print_stringz
    leaq    deck(%rip), %rdi         # RDI = deck pointer for shuffle
    movq    $TOTAL_CARDS, %rsi       # RSI = count
    call    fisher_yates_shuffle
    call    display_deck

    # --- 3. Sattolo Cycle Demo ---
    movq    $stdout, %rdi
    leaq    msg_sattolo(%rip), %rsi
    call    print_stringz
    call    reset_deck               # Reset deck to 1..52
    leaq    deck(%rip), %rdi
    movq    $TOTAL_CARDS, %rsi
    call    sattolo_shuffle
    call    display_deck

    # --- 4. Merge Shuffle Demo ---
    movq    $stdout, %rdi
    leaq    msg_merge(%rip), %rsi
    call    print_stringz
    call    reset_deck
    leaq    deck(%rip), %rdi
    movq    $TOTAL_CARDS, %rsi
    call    merge_shuffle
    call    display_deck

    # --- Exit ---
    movq    $60, %rax                # sys_exit
    xorq    %rdi, %rdi               # status 0
    syscall

# --------------------------------------------------------------------------
# Helper: display_deck
# Matches library: RDI=FD, RSI=buf, RDX=count, RCX=per_line
# --------------------------------------------------------------------------
display_deck:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movq    $stdout, %rdi            # RDI = 1
    leaq    deck(%rip), %rsi         # RSI = pointer to cards
    movq    $TOTAL_CARDS, %rdx       # RDX = 52
    movq    $CARDS_PER_ROW, %rcx     # RCX = 13
    call    print_uint8array
    
    popq    %rbp
    ret

# --------------------------------------------------------------------------
# Helper: reset_deck
# --------------------------------------------------------------------------
reset_deck:
    leaq    deck(%rip), %rdi
    movq    $TOTAL_CARDS, %rcx
.Lfill:
    movb    %cl, -1(%rdi, %rcx)      # Fills 52 down to 1
    loop    .Lfill
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
