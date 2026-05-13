# name        : generate_data.s (AVX2 Optimized)
# description : Fills memory with a value 8 floats at a time
# target      : x86_64-linux

.section .text
.globl generate_data

generate_data:
    # rdi=ptr, rsi=count, xmm0=val
    vbroadcastss %xmm0, %ymm0
    movq %rsi, %rcx
    shrq $3, %rcx
    jz .tail

.loop:
    vmovups %ymm0, (%rdi)
    addq $32, %rdi
    decq %rcx
    jnz .loop

.tail:
    andq $7, %rsi
    jz .done
.tloop:
    vmovss %xmm0, (%rdi)
    addq $4, %rdi
    decq %rsi
    jnz .tloop
.done:
    vzeroupper
    ret

.size generate_data, .-generate_data
.section .note.GNU-stack,"",@progbits
