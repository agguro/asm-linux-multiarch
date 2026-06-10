/* 
 **************************************************************************
 * Name         : cpuid.s
 * Description  : Checks for CPUID support and displays the Vendor ID string.
 *
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * /usr/bin/as --64 -g --noexecstack -I ../../../include \
 * -al=cpuid.lst cpuid.s -o cpuid.o
 *
 * 2. Link Executable (PIE enabled):
 * /usr/bin/ld -m elf_x86_64 -pie -z noexecstack \
 * --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o cpuid \
 * cpuid.o
 *
 *
 * Overview:
 * The CPUID instruction is the gateway to discovering processor features. 
 * However, before using it, a program must verify it is supported by 
 * attempting to flip Bit 21 (the ID bit) in the RFLAGS register.
 *
 * Logic Flow:
 * 1. Check Support: Attempt to flip the ID bit in RFLAGS. If the bit 
 * remains changed after being pushed and popped, CPUID is supported.
 * 2. CPUID EAX=0: Calling CPUID with EAX set to 0 returns a 12-character 
 * Vendor ID string spread across three registers: EBX, EDX, and ECX.
 * 3. Sequence: For "GenuinIintel", the order is EBX (Genu), EDX (ineI), 
 * and ECX (ntel).
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
.list

.section .rodata
    msg_prefix:     .ascii "The processor Vendor ID is '"
    msg_prefix_len = . - msg_prefix

    msg_suffix:     .ascii "'\n"
    msg_suffix_len = . - msg_suffix

    msg_error:      .ascii "CPUID is not supported\n"
    msg_error_len = . - msg_error

.section .bss
    .lcomm vendor_id, 12            # Reserve 12 bytes for Vendor ID string

.section .text
    .globl _start

_start:
    # --- Step 1: Check for CPUID Support ---
    # Bit 21 (ID bit) in FLAGS indicates support for the CPUID instruction.
    pushfq
    popq    %rax
    movq    %rax, %rcx              # Save original RFLAGS
    xorq    $0x200000, %rax         # Flip bit 21
    pushq   %rax
    popfq                           # Attempt to set new RFLAGS
    pushfq
    popq    %rax                    # Read RFLAGS back
    xorq    %rcx, %rax              # Compare with the original
    testq   $0x200000, %rax 
    jz      .no_support             # Jump if bit 21 could not be flipped

    # --- Step 2: Get CPUID Data ---
    movl    $0, %eax                # Function 0: Get Vendor ID
    cpuid                           # Returns string in EBX, EDX, ECX



    # Get address of BSS buffer via RIP-relative addressing
    leaq    vendor_id(%rip), %rdi
    
    # Store the 12-byte Vendor ID (Order: EBX, EDX, ECX)
    movl    %ebx, (%rdi)            # First 4 bytes
    movl    %edx, 4(%rdi)           # Next 4 bytes
    movl    %ecx, 8(%rdi)           # Final 4 bytes

    # --- Step 3: Print Sequence ---
    
    # 1. Print Prefix
    leaq    msg_prefix(%rip), %rsi
    movq    $msg_prefix_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # 2. Print The Vendor ID
    leaq    vendor_id(%rip), %rsi
    movq    $12, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # 3. Print Suffix
    leaq    msg_suffix(%rip), %rsi
    movq    $msg_suffix_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # Exit success
    xorq    %rdi, %rdi              # Exit status 0
    movq    $exit, %rax             # sys_exit
    syscall

.no_support:
    # Print Error and Exit with status 1
    leaq    msg_error(%rip), %rsi
    movq    $msg_error_len, %rdx
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall
    
    movq    $1, %rdi                # Exit status 1
    movq    $exit, %rax
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
