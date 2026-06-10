/*
 **************************************************************************
 * Name          : readfile.s
 * Description   : Displays the contents of a file in plain text.
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=readfile.lst readfile.s -o readfile.o
 *
 * 2. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o readfile \
 * readfile.o
 *
 * Strategy:
 * 1. Extract argc and argv[1] from the stack.
 * 2. Open the file via sys_open. If failed, display error in hex.
 * 3. Use sys_fstat to determine file size (st_size).
 * 4. Loop using the file size, reading 1 byte at a time (sys_read).
 * 5. Output each byte to stdout (sys_write).
 * 6. Close the file descriptor and exit.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
    .equ ST_SIZE_OFF,   48          # Offset of st_size in stat struct
.list

.section .bss
    .align 16
    .Lchar_buffer:  .skip 1
    .Lstat_buf:     .skip 144       # x86_64 stat structure size

.section .rodata
    .Lmsg_usage:    .ascii "usage: readfile filename\n"
    .equ .Lmsg_usage_len, . - .Lmsg_usage
    .Lmsg_error:    .ascii "The program terminated with error: 0x"
    .equ .Lmsg_error_len, . - .Lmsg_error
    .Lcrlf:         .ascii "\n"

.section .text
    .globl _start

_start:
    # On entry, RSP points to argc. We need to check if argc > 1
    popq    %rax                    # rax = argc
    cmpq    $2, %rax
    jl      .LshowUsage

    popq    %rax                    # argv[0] (trash)
    popq    %rdi                    # argv[1] (filename pointer)
    
    # 1. Open the file
    xorl    %esi, %esi              # %esi = O_RDONLY (0)
    movl    $open, %eax
    syscall
    
    testq   %rax, %rax
    js      .Lerror                 # Jump if negative (error code)
    pushq   %rax                    # Save File Descriptor on stack

    # 2. Get file size via fstat
    movq    %rax, %rdi              # fd
    leaq    .Lstat_buf(%rip), %rsi
    movl    $fstat, %eax
    syscall
    
    leaq    .Lstat_buf(%rip), %rax
    movq    ST_SIZE_OFF(%rax), %r12 # r12 = file size (callee-saved)

    testq   %r12, %r12              # Check if file is empty
    jz      .LCloseFile

    # 3. Read Loop
.LreadLoop:
    movq    (%rsp), %rdi            # Get FD from top of stack
    leaq    .Lchar_buffer(%rip), %rsi
    movl    $1, %edx                # Read 1 byte
    movl    $read, %eax
    syscall
    
    testq   %rax, %rax              # Check for EOF or error
    jle     .LCloseFile

    # Print the byte
    leaq    .Lchar_buffer(%rip), %rsi
    movl    $1, %edx
    call    .Lprint
    
    decq    %r12                    # Manual dec/jnz is faster than 'loop'
    jnz     .LreadLoop

    call    .LprintCRLF
      
.LCloseFile:
    popq    %rdi                    # Restore FD into RDI for close
    movl    $close, %eax
    syscall
    jmp     .Lexit

.LshowUsage:
    leaq    .Lmsg_usage(%rip), %rsi
    movl    $.Lmsg_usage_len, %edx
    call    .Lprint
    jmp     .Lexit
      
.Lerror:
    # Error code is in %rax
    pushq   %rax                    # Save error code
    leaq    .Lmsg_error(%rip), %rsi
    movl    $.Lmsg_error_len, %edx
    call    .Lprint
    
    popq    %rax                    # Restore error code
    negq    %rax                    # Convert to positive for hex display
    
    xorl    %r14d, %r14d            # %r14d = 0 (Leading zero flag)
    movl    $16, %ecx               # 16 nibbles for 64-bit value
.LgetNextBits:
    pushq   %rcx
    rolq    $4, %rax                # Move next nibble to low bits
    movq    %rax, %rdx
    andq    $0x0F, %rdx             # Mask nibble
    
    testl   %r14d, %r14d            # Have we seen a non-zero yet?
    jnz     .LprintDigit
    testl   %edx, %edx
    jz      .Lskip                  # Still skipping leading zeros
    incl    %r14d                   # Found first non-zero
    
.LprintDigit:
    cmpb    $9, %dl
    jbe     .LtoASCII
    addb    $7, %dl                 # Adjust for A-F
.LtoASCII:
    addb    $'0', %dl
    leaq    .Lchar_buffer(%rip), %r8
    movb    %dl, (%r8)
    movq    %r8, %rsi
    movl    $1, %edx
    call    .Lprint
.Lskip:
    popq    %rcx
    loop    .LgetNextBits           # Loop still useful for hex conversion
    call    .LprintCRLF

.Lexit:      
    movl    $exit, %eax
    xorl    %edi, %edi
    syscall

# --- Internal Helpers ---

.Lprint:
    pushq   %rax
    pushq   %rdi
    pushq   %rcx
    pushq   %r11                    # Syscall clobbers %rcx and %r11
    movl    $write, %eax
    movl    $stdout, %edi
    syscall
    popq    %r11
    popq    %rcx
    popq    %rdi
    popq    %rax
    ret

.LprintCRLF:
    leaq    .Lcrlf(%rip), %rsi
    movl    $1, %edx
    call    .Lprint
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
