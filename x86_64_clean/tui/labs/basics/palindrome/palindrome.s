/*
 **************************************************************************
 * Name          : palindrome.s
 * Description   : Checks if command line arguments are palindromes.
 *
 * Build Sequence:
 * 1. Assemble Project:
 * /usr/bin/as --64 -g -I ../../../include palindrome.s -o palindrome.o
 * /usr/bin/as --64 -g strlen.s -o strlen.o
 * /usr/bin/as --64 -g print_stringz.s -o print_stringz.o
 *
 * 2. Link Executable:
 * /usr/bin/ld -m elf_x86_64 -pie --dynamic-linker /lib64/ld-linux-x86-64.so.2 \
 * -o palindrome palindrome.o strlen.o print_stringz.o
 *
 * Strategy:
 * 1. Utilize external 'strlen' for high-performance length detection.
 * 2. Utilize external 'print_stringz' for ABI-safe terminal output.
 * 3. Perform a head-to-tail byte comparison to determine palindrome status.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
.list

.extern strlen
.extern print_stringz

.section .rodata
    usage_msg:  .ascii "Palindrome by agguro.\nusage: palindrome string1 ...\n\0"
    txt_is:     .ascii " is \0"
    txt_no:     .ascii "not \0"
    txt_yes:    .ascii "a palindrome.\n\0"

.section .text
    .globl _start

_start:
    popq    %r12                    # r12 = argc
    cmpq    $2, %r12                # Need at least one argument
    jl      .LnoArguments
    
    popq    %rax                    # Skip argv[0]
    decq    %r12                    # Adjust count for loop

.Lmain_loop:
    popq    %r13                    # r13 = current string pointer (argv[i])
    
    # 1. Print the string itself
    movl    $stdout, %edi
    movq    %r13, %rsi
    call    print_stringz

    # 2. Print " is "
    movl    $stdout, %edi
    leaq    txt_is(%rip), %rsi
    call    print_stringz

    # 3. Check Palindrome Logic
    movq    %r13, %rdi
    call    palindrome_check        # Returns CF=1 if NOT palindrome
    
    jnc     .Lprint_yes
    
    # 4. Print "not " if check failed
    movl    $stdout, %edi
    leaq    txt_no(%rip), %rsi
    call    print_stringz

.Lprint_yes:
    # 5. Print "a palindrome."
    movl    $stdout, %edi
    leaq    txt_yes(%rip), %rsi
    call    print_stringz

    decq    %r12
    jnz     .Lmain_loop
    jmp     .Lexit

.LnoArguments:
    movl    $stderr, %edi
    leaq    usage_msg(%rip), %rsi
    call    print_stringz

.Lexit:
    movq    $60, %rax               # sys_exit
    xorq    %rdi, %rdi
    syscall

# --- Internal Logic: Palindrome Check ---
# Input:  %rdi = string pointer
# Output: Carry Flag (CF) set if NOT palindrome, cleared if IS palindrome.
palindrome_check:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rsi
    pushq   %rdi

    # Get length using your external lib
    call    strlen                  # %rax = length
    
    testq   %rax, %rax
    jz      .Lis_pali               # Empty string is a palindrome
    
    movq    (%rsp), %rsi            # Head pointer
    leaq    (%rsi, %rax), %rdi      
    decq    %rdi                    # Tail pointer (Length - 1)
    
    shrq    $1, %rax                # We only need to check half the string
    movq    %rax, %rcx
    jz      .Lis_pali               # Single char is a palindrome

.Lcheck_loop:
    movb    (%rsi), %al
    movb    (%rdi), %dl
    cmpb    %al, %dl
    jne     .Lnot_pali
    incq    %rsi
    decq    %rdi
    loop    .Lcheck_loop

.Lis_pali:
    clc                             # Clear carry: Success
    jmp     .Lcheck_done
.Lnot_pali:
    stc                             # Set carry: Failure
.Lcheck_done:
    popq    %rdi
    popq    %rsi
    popq    %rbp
    ret
    
.size _start, . - _start
.section .note.GNU-stack,"",@progbits

