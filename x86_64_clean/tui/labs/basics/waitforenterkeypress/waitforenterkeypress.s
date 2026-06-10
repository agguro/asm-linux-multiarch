/*
 **************************************************************************
 * Name          : waitforenterkeypress.s
 * Description   : Displays "Press ENTER to exit..." and waits for the 
 * return key (0x0A) in raw mode.
 *
 * Build Sequence:
 * 1. Assemble Project:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=waitforenterkeypress.lst waitforenterkeypress.s \
 * -o waitforenterkeypress.o
 *
 * 2. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o waitforenterkeypress \
 * waitforenterkeypress.o
 *
 * Strategy:
 * 1. Print the prompt to stdout.
 * 2. Use ioctl (TCGETS/TCSETS) to disable ICANON and ECHO.
 * 3. Read input byte-by-byte in a loop until 0x0A (LF) is detected.
 * 4. Restore original terminal settings and exit.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
    .equ TCGETS, 0x5401
    .equ TCSETS, 0x5402
    .equ ICANON, 2
    .equ ECHO,   8
.list

.section .bss
    .align 16
    .Ltermios: .skip 60
    .Lbuffer:  .skip 8

.section .rodata
    .Lmessage: .ascii "Press ENTER to exit..."
    .equ .Lmessage_len, . - .Lmessage

.section .text
    .globl _start

_start:
    # 1. Write prompt to STDOUT
    movl    $write, %eax
    movl    $stdout, %edi
    leaq    .Lmessage(%rip), %rsi
    movl    $.Lmessage_len, %edx
    syscall

    # 2. Configure Terminal (Turn off Canonical and Echo)
    call    termios_canonical_off
    call    termios_echo_off

    # 3. Wait for the specific key (0x0A = LF/ENTER)
.Lrepeat:
    movl    $read, %eax
    movl    $stdin, %edi
    leaq    .Lbuffer(%rip), %rsi
    movl    $1, %edx                # Read 1 byte
    syscall
    
    leaq    .Lbuffer(%rip), %r8
    movb    (%r8), %al
    cmpb    $10, %al                # Compare to Line Feed (Enter)
    jne     .Lrepeat

    # 4. Cleanup: Print a newline and restore terminal settings
    leaq    .Lbuffer(%rip), %rsi
    movb    $10, (%rsi)
    movl    $write, %eax
    movl    $stdout, %edi
    movl    $1, %edx
    syscall

    call    termios_canonical_on
    call    termios_echo_on

    movl    $exit, %eax
    xorl    %edi, %edi
    syscall

# --- Termios Helper Functions ---

termios_canonical_on:
    movl $ICANON, %eax
    jmp .Lset_flag
termios_canonical_off: 
    movl $ICANON, %eax
    jmp .Lclear_flag
termios_echo_on:
    movl $ECHO,   %eax
    jmp .Lset_flag
termios_echo_off:
    movl $ECHO,   %eax

.Lclear_flag:
    pushq   %rax
    call    .Lread_state
    popq    %rax
    notl    %eax
    leaq    .Ltermios(%rip), %rdx
    andl    %eax, 12(%rdx)          # c_lflag is at offset 12
    jmp     .Lwrite_state

.Lset_flag:
    pushq   %rax
    call    .Lread_state
    popq    %rax
    leaq    .Ltermios(%rip), %rdx
    movb    12(%rdx), %cl    # Load the specific flag byte into CL
    orb     %al, %cl         # OR the bitmask (from AL) into CL
    movb    %cl, 12(%rdx)    # Store it back

.Lwrite_state:
    movq    $TCSETS, %rsi
    jmp     .Lioctl_sys
.Lread_state:
    movl    $TCGETS, %esi
.Lioctl_sys:
    leaq    .Ltermios(%rip), %rdx
    movq    $stdin, %rdi
    movq    $ioctl, %rax
    syscall
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
