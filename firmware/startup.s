# =============================================================================
# File        : startup.s
# Project     : WaveGuard SoC Bare-Metal Reset Vector & Startup
# Description : RV32IMC startup sequence for VeeR EL2 / WaveGuard SoC
# =============================================================================

.section .text
.globl _start
.globl add
.globl main

_start:
    # Initialize stack pointer to top of 64KB RAM (0x0000FF00)
    lui     sp, 0x10
    addi    sp, sp, -256

    # Call main()
    jal     ra, main

    # Result of main() is in a0 (expected 30 / 0x1E)
    # Store return value to mailbox location 0x00000100
    lui     t0, 0x0
    sw      a0, 0x100(t0)

    # Signal completion / loop
_finish:
    j       _finish

add:
    add     a0, a0, a1
    ret

main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    
    # x = 10 (0x0A)
    li      a0, 10
    # y = 20 (0x14)
    li      a1, 20
    
    jal     ra, add
    
    # a0 now contains 30 (0x1E)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
