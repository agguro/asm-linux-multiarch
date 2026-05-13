/* 
 ***************************************************************************
 * Name         : print_stringz.s
 * Assemble     : as --64 print_stringz.s -o print_stringz.o
 * Description  : Prints a NULL-terminated string to a specified FD.
 *
 * Input        : %rdi = File Descriptor (1=stdout, 2=stderr)
 * %rsi = Pointer to NULL-terminated string
 * Output       : None (Registers are restored)
 *
 * Strategy:
 * This function is "ABI Transparent." It saves every register that could 
 * potentially be changed by a function call (strlen) or a Linux syscall 
 * (write). This allows the caller to use it without worrying about losing
 * data in volatile registers like %rax, %rcx, or %r11.
 * **************************************************************************
 */

.globl print_stringz
.type print_stringz, @function
.extern strlen

.section .text
print_stringz:
    pushq   %rbp
    movq    %rsp, %rbp
    
    # Save all registers clobbered by strlen or syscall
    # Standard syscalls clobber %rcx and %r11
    pushq   %rax
    pushq   %rcx
    pushq   %rdx
    pushq   %rsi
    pushq   %rdi
    pushq   %r11

    # 1. Prepare for strlen
    movq    %rsi, %rdi      # Move string pointer to rdi for strlen
    call    strlen          # RAX = length of string
    
    # 2. Syscall Setup (sys_write)
    movq    %rax, %rdx      # Arg 3: Count (from strlen)
    # Arg 2: Buffer pointer remains in %rsi from the caller
    # Arg 1: Retrieve original FD from stack (8 bytes above %r11)
    movq    8(%rsp), %rdi   
    movq    $1, %rax        # syscall 1 is sys_write
    syscall



    # 3. Restore Everything (Exact reverse order of pushes)
    popq    %r11
    popq    %rdi
    popq    %rsi
    popq    %rdx
    popq    %rcx
    popq    %rax
    
    popq    %rbp
    ret

.size print_stringz, .-print_stringz
.section .note.GNU-stack,"",@progbits
