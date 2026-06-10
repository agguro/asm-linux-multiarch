/*
 * ============================================================================
 * Name        : keyfilter.s
 * Description : A terminal utility that captures keystrokes in raw mode and 
 *               prints their ASCII values as Hexadecimal.
 *
 * Technical Overview:
 * 1. Terminal Control: Uses 'ioctl' to disable ICANON (buffered input) and 
 *    ECHO, allowing the program to react to single keys immediately.
 * 2. Performance: Employs a branch-free nibble-to-hex conversion algorithm 
 *    using 'setge' and 'imul' to avoid CPU pipeline stalls.
 * 3. Feature: Position Independent Code (PIC) using RIP-relative addressing.
 *
 * Build Sequence:
 * 1. Assemble:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include -o keyfilter.o keyfilter.s
 *
 * 2. Link (PIE):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o keyfilter keyfilter.o
 * ============================================================================
 */

.nolist
    .include "unistd.inc"
    .equ TCGETS, 0x5401
    .equ TCSETS, 0x5402
.list

.section .bss
    .align 16
    .Lbuffer:       .skip 16          
    .Lrolling:      .skip 4           
    .Ltermios_orig: .skip 60          
    .Ltermios_work: .skip 60          

.section .rodata
    .Lintro:
        .ascii "KeyFilter 2026 - Pure Assembly Edition\n"
        .ascii "Type 'QUIT' to exit.\n"
        .ascii "start typing >> "
    .equ .Lintro_len, . - .Lintro

    .Leol:
        .ascii "\n"
    .equ .Leol_len, . - .Leol

.section .data
    .Loutput:      .ascii "00 "      
    .equ .Loutput_len, . - .Loutput
    
.section .text
.globl _start

_start:
    # 1. Clear rolling buffer
    leaq    .Lrolling(%rip), %rax
    movl    $0, (%rax)

    # 2. Print Intro Message
    movl    $write, %eax
    movl    $stdout, %edi
    leaq    .Lintro(%rip), %rsi
    movl    $.Lintro_len, %edx
    syscall

    # 3. Get Original Terminal State
    movl    $ioctl, %eax
    xorl    %edi, %edi              # stdin
    movl    $TCGETS, %esi
    leaq    .Ltermios_orig(%rip), %rdx
    syscall

    # 4. Clone State to Work Buffer (Fast String Copy)
    leaq    .Ltermios_orig(%rip), %rsi
    leaq    .Ltermios_work(%rip), %rdi
    movl    $7, %ecx                # Copy 7 quadwords (56 bytes)
    rep     movsq

    # 5. Modify Work State (Disable ICANON and ECHO)
    leaq    .Ltermios_work(%rip), %rbx
    movb    12(%rbx), %al           # Offset 12 is c_lflag
    andb    $~(0x02 | 0x08), %al    # Clear bits for ICANON(2) and ECHO(8)
    movb    %al, 12(%rbx)

    # 6. Apply Work State
    movl    $ioctl, %eax
    xorl    %edi, %edi
    movl    $TCSETS, %esi
    movq    %rbx, %rdx
    syscall

.Lmain_loop:
    # 7. Read Input
    movl    $read, %eax
    xorl    %edi, %edi
    leaq    .Lbuffer(%rip), %rsi
    movl    $16, %edx
    syscall 
    
    testq   %rax, %rax
    jle     .Lexit_restore

    movq    %rax, %r12               # Count of bytes read
    xorl    %r13d, %r13d             # Byte index = 0

.Lprocess_bytes:
    leaq    .Lbuffer(%rip), %rbx
    movzbq  (%rbx, %r13), %rdi       # Get the current key byte
    
    # --- Rolling Buffer Update ---
    leaq    .Lrolling(%rip), %rcx
    movl    (%rcx), %eax             
    shll    $8, %eax                 
    orb     %dil, %al                
    movl    %eax, (%rcx)             
    
    # Exit if "QUIT" (Q=51, U=55, I=49, T=54)
    cmpl    $0x51554954, %eax
    je      .Lexit_restore

    # --- Inlined Branch-Free Hex Conversion ---
    movb    %dil, %al                # High nibble processing
    shrb    $4, %al                  
    cmpb    $10, %al
    setge   %cl                      
    movzbl  %cl, %ecx
    imull   $7, %ecx, %ecx           
    addb    $'0', %al
    addb    %cl, %al                 
    movb    %al, %ah                 # Result High in AH

    movb    %dil, %al                # Low nibble processing
    andb    $0x0F, %al               
    cmpb    $10, %al
    setge   %cl
    movzbl  %cl, %ecx
    imull   $7, %ecx, %ecx
    addb    $'0', %al
    addb    %cl, %al                 # Result Low in AL
    
    # --- Print Hex Output ---
    leaq    .Loutput(%rip), %rsi
    movb    %ah, (%rsi)              
    movb    %al, 1(%rsi)             
    
    movl    $write, %eax
    movl    $stdout, %edi
    movl    $.Loutput_len, %edx
    syscall

    incq    %r13
    cmpq    %r12, %r13
    jl      .Lprocess_bytes          
    
    jmp     .Lmain_loop
  
.Lexit_restore:
    # 8. Restore Original Terminal State
    movl    $ioctl, %eax
    xorl    %edi, %edi
    movl    $TCSETS, %esi
    leaq    .Ltermios_orig(%rip), %rdx
    syscall

    # 9. Print end of line
    movl    $write, %eax
    movl    $stdout, %edi
    leaq    .Leol(%rip), %rsi
    movl    $.Leol_len, %edx
    syscall

    # 10. Final Exit
    movl    $exit, %eax
    xorl    %edi, %edi
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
