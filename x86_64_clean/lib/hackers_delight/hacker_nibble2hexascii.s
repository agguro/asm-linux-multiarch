# -----------------------------------------------------------------------------
# Name:        hacker_nibble2hexascii
# Author:      Hacker's Delight Style (Henry S. Warren Jr. inspiration)
# Description: Converts a 64-bit GPR to 16 Hex-ASCII characters.
# Logic:       Branchless SBB trick (no lookup table, no memory access).
# C Prototype: extern "C" void hacker_nibble2hex(uint64_t val, char* buf);
# -----------------------------------------------------------------------------

    .section .text
    .global hacker_nibble2hexascii
    .type   hacker_nibble2hexascii, @function

hacker_nibble2hexascii:
    # RDI = input value (64-bit)
    # RSI = destination buffer (must be at least 16 bytes)

    mov     $16, %rcx                 # 16 nibbles in a 64-bit register

.L_hexloop:
    rol     $4, %rdi                  # rotate next nibble into low bits
    mov     %dil, %al                 # copy low byte
    and     $0x0F, %al                # isolate nibble (0–15)

    # --- Hacker's Delight branchless hex conversion ---
    cmp     $10, %al                  # CF = (AL < 10)
    sbb     $0x69, %al                # AL = AL - 0x69 - CF
    and     $0x1F, %al                # keep low 5 bits
    add     $0x20, %al                # normalize to ASCII ('0'–'9','A'–'F')
    # --------------------------------------------------

    mov     %al, (%rsi)               # store ASCII char
    inc     %rsi                      # advance buffer pointer
    loop    .L_hexloop                # RCX--, continue if not zero

    ret

.size hacker_nibble2hexascii, . - hacker_nibble2hexascii

.section .note.GNU-stack,"",@progbits
