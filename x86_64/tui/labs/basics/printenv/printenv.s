/*
 **************************************************************************
 * Name          : printenv.s
 * Description   : Linux environment variable printer. Supports -0/--null,
 * --help, and --version.
 *
 * Build Sequence:
 * 1. Assemble Project:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=printenv.lst printenv.s -o printenv.o
 *
 * 2. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o printenv printenv.o
 *
 * Strategy:
 * 1. Parse command-line arguments (argv) for options starting with '-'.
 * 2. If --null is requested, change the end-of-line character to 0.
 * 3. Access envp by skipping argc and all argv pointers on the stack.
 * 4. Iterate through envp strings and print those that match the request.
 * 5. If no variable is requested, print the entire envp list.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
.list

.extern strlen
.extern print_stringz

.section .bss
    .align 16
    .Lbuffer:       .skip 1

.section .data
    # Added a null terminator so print_stringz works correctly
    .Lendofline:    .byte 10, 0        

.section .rodata
    .Lusage:
        .ascii "Usage: ./printenv [OPTION]... [VARIABLE]...\n"
        .ascii "Print the values of the specified environment VARIABLE(s).\n\n"
        .ascii "-0, --null      end each output line with 0 byte rather than newline\n"
        .ascii "    --help      display this help and exit\n"
        .ascii "    --version   output version information and exit\n\0"
    
    .Lversion:
        .ascii "printenv (GAS x86_64) 0.01\n"
        .ascii "NASM version written by agguro\n\0"
    
    .Linvalid:      .ascii "printenv: invalid option '\0"
    .Loption_msg:   .ascii "'\nTry `printenv --help` for more information.\n\0"
    
.section .text
    .globl _start

_start:
    popq    %rbx                    # argc
    popq    %rax                    # argv[0]
    cmpq    $1, %rbx
    je      .LGetAllVariables            

    # Get first argument (argv[1])
    popq    %rsi                    
    movq    %rsi, %r15              # Save pointer for error msg
    
    cld
    lodsb                           # Load first char
    cmpb    $'-', %al               # Is it an option?
    je      .LHandleOptions
    
    # Not an option: search for specific variable
    decq    %rsi                    
    pushq   %rsi                    # Push target name to stack
    jmp     .LGetVariable

.LHandleOptions:
    lodsb
    cmpb    $'0', %al
    je      .LIsNull
    cmpb    $'-', %al
    jne     .LInvalidOption             
    
    # Simple Long Option Parsing (help/null/version)
    lodsl                           # Load 4 bytes into EAX
    cmpl    $0x706c6568, %eax       # "help"
    je      .LIsHelp
    cmpl    $0x6c6c756e, %eax       # "null"
    je      .LIsNull
    
    # Check for "version"
    decq    %rsi
    movq    (%rsi), %rax
    movabsq $0x6e6f6973726576, %r8  # "version"
    cmpq    %r8, %rax
    je      .LIsVersion
    jmp     .Lexit

.LIsNull:
    leaq    .Lendofline(%rip), %rax
    movb    $0, (%rax)              # Change newline to null
    cmpq    $2, %rbx                # Was it just './printenv -0'?
    jne     .LGetVariable
    jmp     .LGetAllVariables

.LIsHelp:
    movl    $stdout, %edi
    leaq    .Lusage(%rip), %rsi
    call    print_stringz
    jmp     .Lexit

.LIsVersion:
    movl    $stdout, %edi
    leaq    .Lversion(%rip), %rsi
    call    print_stringz
    jmp     .Lexit

.LInvalidOption:
    movl    $stderr, %edi
    leaq    .Linvalid(%rip), %rsi
    call    print_stringz
    
    # Print the specific character that failed
    movl    $stderr, %edi
    movq    %r15, %rsi
    # We only want to print the char, so we temporarily null-terminate or use write
    movl    $write, %eax
    movl    $2, %edx                # Print the "-" and the char
    syscall

    movl    $stderr, %edi
    leaq    .Loption_msg(%rip), %rsi
    call    print_stringz
    jmp     .Lexit

.LGetAllVariables:
    popq    %rsi                    # Skip NULL terminator of argv
.LNextVariable:    
    popq    %rsi                    # Get envp[i] pointer
    testq   %rsi, %rsi              # End of envp?
    jz      .Lexit
    
    movl    $stdout, %edi
    call    print_stringz           # Print NAME=VALUE
    
    movl    $stdout, %edi
    leaq    .Lendofline(%rip), %rsi
    call    print_stringz           # Print EOL
    jmp     .LNextVariable

.LGetVariable:
    popq    %rdi                    # Target variable name
    pushq   %rdi
    call    strlen                  # Use library strlen!
    movq    %rax, %rcx              # RCX = length of search name
    
    popq    %rdi                    # Restore target name
    popq    %rsi                    # Skip NULL argv spacer
.LgetNV:
    popq    %rsi                    # Get next envp string
    testq   %rsi, %rsi
    jz      .Lexit                  # Not found
    
    pushq   %rdi
    pushq   %rcx
    pushq   %rsi                    
    
    repe    cmpsb                   # Compare strings
    jne     .LnoMatch
    
    cmpb    $'=', (%rsi)            # Is it followed by '='?
    je      .LFoundMatch

.LnoMatch:
    popq    %rsi
    popq    %rcx
    popq    %rdi
    jmp     .LgetNV

.LFoundMatch:
    incq    %rsi                    # Skip '='
    movl    $stdout, %edi           # %rsi points to the value
    call    print_stringz           
    
    movl    $stdout, %edi
    leaq    .Lendofline(%rip), %rsi
    call    print_stringz

.Lexit:
    movl    $exit, %eax
    xorl    %edi, %edi
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits

