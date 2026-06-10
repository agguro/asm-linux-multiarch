/*
 **************************************************************************
 * Name          : waitanykeypress.s
 * Description   : Displays "Press any key to exit..." and exits as soon
 * as the first character is received in raw mode.
 *
 * Build Sequence:
 * 1. Assemble Project:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=waitanykeypress.lst waitanykeypress.s \
 * -o waitanykeypress.o
 *
 * 2. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o waitanykeypress \
 * waitanykeypress.o
 *
 * Strategy:
 * 1. Print the prompt to stdout.
 * 2. Use ioctl (TCGETS/TCSETS) to disable ICANON and ECHO.
 * 3. Call read. In non-canonical mode, this returns on the first key.
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
    .Lmessage: .ascii "Press any key to exit..."
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

    # 3. Read (Returns immediately on any keypress in non-canonical mode)
    movl    $read, %eax
    movl    $stdin, %edi
    leaq    .Lbuffer(%rip), %rsi
    movl    $1, %edx                # Read 1 byte
    syscall
    
    # 4. Cleanup: Print a newline and restore terminal settings
    leaq    .Lbuffer(%rip), %rsi
    movb    $10, (%rsi)             # Put a newline char in the buffer
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
    notq    %rax
    leaq    .Ltermios(%rip), %rdx
    andq    %rax, 12(%rdx)          # Clear the bit in c_lflag
    jmp     .Lwrite_state

.Lset_flag:
    pushq   %rax
    call    .Lread_state
    popq    %rax
    leaq    .Ltermios(%rip), %rdx
    orq     %rax, 12(%rdx)          # Set the bit in c_lflag

.Lwrite_state:
    movq    $TCSETS, %rsi
    jmp     .Lioctl_sys
.Lread_state:
    movq    $TCGETS, %rsi
.Lioctl_sys:
    leaq    .Ltermios(%rip), %rdx
    movq    $stdin, %rdi
    movq    $ioctl, %rax
    syscall
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
