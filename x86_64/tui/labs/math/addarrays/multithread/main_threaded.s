# name        : main_threaded.s
# description : Threaded AVX2 with mmap, dynamic discovery, and Nanosecond Timing
# target      : x86_64-linux (link with -lpthread -lc)

.equ _SC_NPROCESSORS_ONLN, 84
.equ TOTAL_SIZE, 1000000        # Try 1000000000 for the server!
.equ FLOAT_SIZE, 4

# mmap constants
.equ MAP_PRIVATE, 0x02
.equ MAP_ANONYMOUS, 0x20
.equ PROT_READ, 0x1
.equ PROT_WRITE, 0x2
.equ SYS_CLOCK_GETTIME, 228
.equ CLOCK_REALTIME, 0

.section .data
    fmt_cores:  .asciz "CPUs detected: %ld. Spawning %ld threads.\n"
    fmt_stats:  .asciz "Workload: %ld per thread (Last: %ld). Total: %ld floats.\n"
    fmt_verify: .asciz "Verification:\n  First element: %.2f\n  Last element:  %.2f\n"
    fmt_done:   .asciz "Multi-threaded AVX2 processing complete.\n"
    fmt_time:   .asciz "Execution Time: %ld.%09ld seconds\n"
    
    # Pointer storage
    array_a_ptr:  .quad 0
    array_b_ptr:  .quad 0
    result_ptr:   .quad 0

.section .bss
    .align 16
    t_start:     .skip 16   # tv_sec, tv_nsec
    t_end:       .skip 16
    thread_ids:  .skip 1024
    thread_args: .skip 4096

.section .text
.extern sysconf, pthread_create, pthread_join, printf, exit, generate_data, avx2_thread_bridge
.globl _start

_start:
    pushq %rbp
    movq  %rsp, %rbp
    andq  $-16, %rsp            # Standard stack alignment

    # --- 1. Memory Allocation (mmap) ---
    movq $TOTAL_SIZE, %r15
    imulq $FLOAT_SIZE, %r15     

    movq $3, %r14
    lea array_a_ptr(%rip), %r12

.alloc_loop:
    movq $9, %rax               
    xorq %rdi, %rdi
    movq %r15, %rsi
    movq $3, %rdx               # PROT_READ | PROT_WRITE
    movq $0x22, %r10            # MAP_PRIVATE | MAP_ANONYMOUS
    movq $-1, %r8
    xorq %r9, %r9
    syscall
    movq %rax, (%r12)           
    addq $8, %r12
    decq %r14
    jnz .alloc_loop

    # --- 2. Data Initialization ---
    movq array_a_ptr(%rip), %rdi
    movq $TOTAL_SIZE, %rsi
    movl $0x3fc00000, %eax      # 1.5f
    vmovd %eax, %xmm0
    call generate_data

    movq array_b_ptr(%rip), %rdi
    movq $TOTAL_SIZE, %rsi
    movl $0x40200000, %eax      # 2.5f
    vmovd %eax, %xmm0
    call generate_data

    # --- 3. System Discovery ---
    movq $_SC_NPROCESSORS_ONLN, %rdi
    call sysconf
    movq %rax, %r12             # Core count
    shrq $1, %rax               # Threads = Cores/2
    jnz .set_threads
    movq $1, %rax
.set_threads:
    movq %rax, %r13             # Thread count

    # --- 4. Work Distribution Info ---
    xorq %rdx, %rdx
    movq $TOTAL_SIZE, %rax
    divq %r13
    movq %rax, %r14             # Q
    movq %rdx, %r15             # R

    lea fmt_cores(%rip), %rdi
    movq %r12, %rsi
    movq %r13, %rdx
    xorl %eax, %eax
    call printf

    lea fmt_stats(%rip), %rdi
    movq %r14, %rsi
    movq %r14, %rdx
    addq %r15, %rdx             # Print Q + R for last thread
    movq $TOTAL_SIZE, %rcx
    xorl %eax, %eax
    call printf

    # --- START TIMER ---
    movq $SYS_CLOCK_GETTIME, %rax
    movq $CLOCK_REALTIME, %rdi
    lea t_start(%rip), %rsi
    syscall

    # --- 5. Thread Spawning ---
    xorq %rbx, %rbx
spawn_loop:
    cmpq %r13, %rbx
    je wait_loop

    movq %rbx, %rax
    shlq $5, %rax               # Struct size 32
    lea thread_args(%rip), %rcx
    addq %rax, %rcx

    movq %rbx, %rax
    imulq %r14, %rax
    shlq $2, %rax               # Float offset in bytes

    movq result_ptr(%rip), %r8
    addq %rax, %r8
    movq %r8, 0(%rcx)

    movq array_a_ptr(%rip), %r8
    addq %rax, %r8
    movq %r8, 8(%rcx)

    movq array_b_ptr(%rip), %r8
    addq %rax, %r8
    movq %r8, 16(%rcx)

    movq %r14, %r8              # count = Q
    movq %r13, %r9
    decq %r9
    cmpq %r9, %rbx
    jne .launch
    addq %r15, %r8              # Last thread gets Q + R
.launch:
    movq %r8, 24(%rcx)

    lea thread_ids(%rip), %rdi
    lea (%rdi, %rbx, 8), %rdi
    xorq %rsi, %rsi
    lea avx2_thread_bridge(%rip), %rdx
    call pthread_create

    incq %rbx
    jmp spawn_loop

wait_loop:
    xorq %rbx, %rbx
join_it:
    cmpq %r13, %rbx
    je finish_timing
    lea thread_ids(%rip), %rax
    movq (%rax, %rbx, 8), %rdi
    xorq %rsi, %rsi
    call pthread_join
    incq %rbx
    jmp join_it

finish_timing:
    # --- END TIMER ---
    movq $SYS_CLOCK_GETTIME, %rax
    movq $CLOCK_REALTIME, %rdi
    lea t_end(%rip), %rsi
    syscall

    # Calculate Time Delta
    movq t_end(%rip), %rsi
    subq t_start(%rip), %rsi    # Seconds
    movq t_end+8(%rip), %rdx
    subq t_start+8(%rip), %rdx  # Nanoseconds
    
    jns .print_time
    decq %rsi                   # Borrow sec
    addq $1000000000, %rdx      # Add 1s worth of nsec

.print_time:
    lea fmt_time(%rip), %rdi
    xorl %eax, %eax
    call printf

verify_step:
    andq $-16, %rsp             # Ensure alignment for verification printf
    
    # First element
    movq result_ptr(%rip), %rax
    vmovss (%rax), %xmm0
    vcvtss2sd %xmm0, %xmm0, %xmm0

    # Last element
    movq result_ptr(%rip), %rbx
    movq $TOTAL_SIZE, %rcx
    decq %rcx
    shlq $2, %rcx
    vmovss (%rbx, %rcx), %xmm1
    vcvtss2sd %xmm1, %xmm1, %xmm1

    lea fmt_verify(%rip), %rdi
    movb $2, %al
    call printf

finish:
    lea fmt_done(%rip), %rdi
    xorl %eax, %eax
    call printf

    movq %rbp, %rsp
    popq %rbp
    movq $0, %rdi
    call exit

.size _start, .-_start
.section .note.GNU-stack,"",@progbits
