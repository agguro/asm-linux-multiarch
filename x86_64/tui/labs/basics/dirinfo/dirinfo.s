/* 
 **************************************************************************
 * Name         : dirinfo.s
 * Description  : Displays detailed directory entry information for the 
 * current working directory.
 *
 *
 * Build Sequence:
 * 1. Assemble Project Main:
 * as --64 -g dirinfo.s -o dirinfo.o
 *
 * * 2. Assemble Libraries:
 * as --64 -g strlen.s -o strlen.o
 * as --64 -g print_stringz.s -o print_stringz.o
 * as --64 -g u64toa.s -o u64toa.o
 * as --64 -g u64tohex.s -o u64tohex.o
 *
 * 3. Link Executable:
 * ld -m elf_x86_64 -pie --dynamic-linker /lib64/ld-linux-x86-64.so.2 \
 * -o dirinfo dirinfo.o strlen.o print_stringz.o u64toa.o u64tohex.o
 *
 *
 * Overview:
 * This program utilizes the Linux 'getdents64' syscall to read raw directory
 * structures. It parses the resulting buffer to extract inodes, offsets,
 * record lengths, and file types, formatting them into a readable table.
 *
 * Logic Flow:
 * 1. Opens the current directory (".") using O_DIRECTORY flag.
 * 2. Reads directory entries into a 4KB buffer.
 * 3. Iterates through the buffer using 'd_reclen' to find the next entry.
 * 4. Translates the 'd_type' byte into a human-readable string using a
 * PIE-safe lookup table.
 * 5. Uses external library functions for numeric-to-string conversion.
 * **************************************************************************
 */

.nolist
    .include "unistd.inc"
.list

.equ O_RDONLY, 0
.equ O_DIRECTORY, 0200000

.section .rodata
    tableheader: .asciz "  inode   |   next entry     | record length |        filetype          |  filename  \n"
    totallength: .asciz "                  Total length |"
    spacer:      .asciz " "
    col:         .asciz "|"
    line:        .asciz "---------------------------------------------------------------------------------------------------------\n"
    crlf:        .asciz "\n"
    path:        .asciz "."

    # File Type Strings
    type_unk:    .asciz "unknown           "
    type_reg:    .asciz "regular file      "
    type_dir:    .asciz "directory         "
    type_soc:    .asciz "unix domain socket"
    type_chr:    .asciz "character device  "
    type_lnk:    .asciz "symbolic link     "
    type_blk:    .asciz "block device      "
    type_non:    .asciz "entry without type"
    type_pip:    .asciz "named pipe        "

    .align 8
    type_table:  
    .quad type_unk - type_table
    .quad type_reg - type_table
    .quad type_dir - type_table  
    .quad type_soc - type_table
    .quad type_chr - type_table
    .quad type_lnk - type_table
    .quad type_blk - type_table
    .quad type_non - type_table
    .quad type_pip - type_table

.section .bss
    .align 16
    buffer:      .skip 4096            
    .equ BUFFER_LEN, 4096
    fd:          .quad 0
    nread:       .quad 0
    dirent_buf:  .skip 512             
    conv_buf:    .skip 64              

.section .text
    .globl _start
    .extern strlen
    .extern print_stringz
    .extern u64toa
    .extern u64tohex

_start:
    # 1. Open Directory
    leaq    path(%rip), %rdi
    movq    $(O_RDONLY | O_DIRECTORY), %rsi
    movq    $open, %rax
    syscall
    
    cmpq    $0, %rax
    jl      .Lexit_error
    movq    %rax, fd(%rip)

    # 2. Get Directory Entries
    movq    %rax, %rdi               
    leaq    buffer(%rip), %rsi
    movq    $BUFFER_LEN, %rdx
    movq    $getdents64, %rax
    syscall
    
    cmpq    $0, %rax
    jle     .Lcleanup               
    movq    %rax, nread(%rip)
    
    # 3. Print Header
    movq    $stdout, %rdi
    leaq    line(%rip), %rsi
    call    print_stringz
    leaq    tableheader(%rip), %rsi
    call    print_stringz
    leaq    line(%rip), %rsi
    call    print_stringz
    
    xorq    %r12, %r12                      # r12 = offset tracker
.Lloop:
    leaq    buffer(%rip), %rbx
    addq    %r12, %rbx                      # current d_entry pointer
    movzwq  16(%rbx), %rcx                  # rcx = d_reclen
    
    # Copy record to local buffer
    movq    %rbx, %rsi
    leaq    dirent_buf(%rip), %rdi
    pushq   %rcx                     
    cld
    rep     movsb
    popq    %rcx                     

    leaq    dirent_buf(%rip), %r13          # r13 = local entry floor
    
    # --- Column: Inode ---
    movq    $stdout, %rdi
    leaq    spacer(%rip), %rsi
    call    print_stringz

    movq    (%r13), %rdi                    # d_ino
    call    .Lprepare_conv_buffer
    call    u64toa
    call    .Lprint_lib_output              # Uses print_stringz on numeric result
    
    leaq    spacer(%rip), %rsi
    call    print_stringz
    leaq    col(%rip), %rsi
    call    print_stringz
    
    # --- Column: Offset (Hex) ---
    leaq    spacer(%rip), %rsi
    call    print_stringz
    movq    8(%r13), %rdi                   # d_off
    call    .Lprepare_conv_buffer
    call    u64tohex
    call    .Lprint_lib_output
    
    leaq    spacer(%rip), %rsi
    call    print_stringz
    leaq    col(%rip), %rsi
    call    print_stringz
    
    # --- Column: Record Length ---
    movq    $6, %rax
    call    .Lprint_spacers
    movzwq  16(%r13), %rdi                  # d_reclen
    call    .Lprepare_conv_buffer
    call    u64toa
    call    .Lprint_lib_output
    
    movq    $1, %rax
    call    .Lprint_spacers
    leaq    col(%rip), %rsi
    call    print_stringz

    # --- Column: File Type ---
    leaq    spacer(%rip), %rsi
    call    print_stringz
    
    movzbq  18(%r13), %rax                  # d_type numeric index
    andq    $0x0F, %rax                     # Ensure index is within range (0-8)
    
    leaq    type_table(%rip), %rbx          # Get base address of table (PIE-safe)
    movq    (%rbx, %rax, 8), %rsi           # Load the relative OFFSET from table
    addq    %rbx, %rsi                      # Final Pointer = Table Base + Offset
    
    call    print_stringz                   # Now RSI points to a valid string

    leaq    col(%rip), %rsi
    call    print_stringz

    # --- Column: Name ---
    leaq    spacer(%rip), %rsi
    call    print_stringz
    leaq    19(%r13), %rsi                  # d_name
    call    print_stringz
    
    leaq    crlf(%rip), %rsi
    call    print_stringz
    
    # Advance
    movzwq  16(%r13), %rax
    addq    %rax, %r12               
    cmpq    nread(%rip), %r12               
    jl      .Lloop

.Lfooter:
    leaq    line(%rip), %rsi
    call    print_stringz
    leaq    totallength(%rip), %rsi
    call    print_stringz
    movq    nread(%rip), %rdi
    call    .Lprepare_conv_buffer
    call    u64toa
    call    .Lprint_lib_output
    leaq    crlf(%rip), %rsi
    call    print_stringz
      
.Lcleanup:
    movq    fd(%rip), %rdi
    movq    $close, %rax
    syscall

.Lexit_error:
    movq    $exit, %rax
    xorq    %rdi, %rdi
    syscall

# --- Helpers ---

.Lprepare_conv_buffer:
    # Set RSI = start, RDX = 63, and place null at index 63
    leaq    conv_buf(%rip), %rsi
    movq    $63, %rdx
    movb    $0, 63(%rsi)                    # Pre-terminate the buffer
    ret

.Lprint_lib_output:
    # Library returns pointer in RSI
    # Since we pre-terminated, it is a valid Z-string
    movq    $stdout, %rdi
    call    print_stringz
    ret

.Lprint_spacers:
    movq    %rax, %rcx
1:  pushq   %rcx
    leaq    spacer(%rip), %rsi
    movq    $stdout, %rdi
    call    print_stringz
    popq    %rcx
    loop    1b
    ret

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
