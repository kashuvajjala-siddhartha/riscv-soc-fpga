#!/usr/bin/env python3
"""
RISC-V Machine Code & Hex File Generator for Bare-Metal WaveGuard SoC
Compiles the startup sequence and mentor's add(10, 20) test program.
Generates:
  - Verilog $readmemh hex file (program.hex) for 64-bit wide RAM
  - Intel HEX file (program.ihex) matching objcopy -O ihex output
  - Assembly listing / disassembly (program.dis)
"""

import os
import sys

def build_program():
    # Instruction memory layout starting at 0x00000000:
    # 0x00: lui sp, 0x10          (sp = 0x00010000)
    # 0x04: addi sp, sp, -256     (sp = 0x0000FF00)
    # 0x08: jal ra, main          (call main @ 0x24 -> offset +0x1C = +28)
    # 0x0C: lui t0, 0x0           (t0 = 0)
    # 0x10: sw a0, 0x100(t0)      (store return sum to [0x100])
    # 0x14: j 0x14                (infinite finish loop: offset 0)
    # 0x18: add a0, a0, a1        (add function: return a + b)
    # 0x1C: ret (jalr x0, ra, 0)
    # 0x20: nop
    # 0x24: addi sp, sp, -16      (main function)
    # 0x28: sw ra, 12(sp)
    # 0x2C: addi a0, zero, 10     (x = 10)
    # 0x30: addi a1, zero, 20     (y = 20)
    # 0x34: jal ra, add           (call add @ 0x18 -> offset -0x1C = -28)
    # 0x38: lw ra, 12(sp)
    # 0x3C: addi sp, sp, 16
    # 0x40: ret

    def jal_imm(offset, rd=1):
        # J-type: imm[20|10:1|11|19:12] rd opcode(1101111)
        val = offset & 0x1FFFFF
        b20 = (val >> 20) & 1
        b10_1 = (val >> 1) & 0x3FF
        b11 = (val >> 11) & 1
        b19_12 = (val >> 12) & 0xFF
        imm_enc = (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12)
        return imm_enc | (rd << 7) | 0x6F

    instructions = [
        # 0x00: lui sp, 0x10
        (0x00, 0x00010137, "lui     sp, 0x10"),
        # 0x04: addi sp, sp, -256
        (0x04, 0xF0010113, "addi    sp, sp, -256"),
        # 0x08: jal ra, main (offset = +28 = 0x1C)
        (0x08, jal_imm(28, rd=1), "jal     ra, main"),
        # 0x0C: lui t0, 0x0
        (0x0C, 0x000002B7, "lui     t0, 0x0"),
        # 0x10: sw a0, 0x100(t0)
        (0x10, 0x10A2A023, "sw      a0, 256(t0)    # mailbox [0x100] = sum"),
        # 0x14: j _finish (offset = 0)
        (0x14, jal_imm(0, rd=0), "j       _finish"),
        # 0x18: add: add a0, a0, a1
        (0x18, 0x00B50533, "add     a0, a0, a1     # int add(int a, int b)"),
        # 0x1C: ret
        (0x1C, 0x00008067, "ret"),
        # 0x20: nop
        (0x20, 0x00000013, "nop"),
        # 0x24: main: addi sp, sp, -16
        (0x24, 0xFF010113, "addi    sp, sp, -16    # int main()"),
        # 0x28: sw ra, 12(sp)
        (0x28, 0x00112623, "sw      ra, 12(sp)"),
        # 0x2C: li a0, 10
        (0x2C, 0x00A00513, "li      a0, 10         # x = 10"),
        # 0x30: li a1, 20
        (0x30, 0x01400593, "li      a1, 20         # y = 20"),
        # 0x34: jal ra, add (offset = -28 = -0x1C)
        (0x34, jal_imm(-28, rd=1), "jal     ra, add        # return add(x, y)"),
        # 0x38: lw ra, 12(sp)
        (0x38, 0x00C12083, "lw      ra, 12(sp)"),
        # 0x3C: addi sp, sp, 16
        (0x3C, 0x01010113, "addi    sp, sp, 16"),
        # 0x40: ret
        (0x40, 0x00008067, "ret")
    ]

    return instructions

def write_hex_files(instructions, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    
    # 1. Disassembly file
    dis_path = os.path.join(out_dir, "program.dis")
    with open(dis_path, "w") as f:
        f.write("; WaveGuard SoC RISC-V Disassembly\n")
        f.write("; Target: RV32I / VeeR-EL2\n\n")
        for addr, code, asm in instructions:
            f.write(f"0x{addr:08x}:  {code:08x}    {asm}\n")
    print(f"Generated: {dis_path}")

    # 2. Verilog 64-bit $readmemh hex file
    # Combine two 32-bit instructions per 64-bit word: [word1 (hi), word0 (lo)]
    mem_words = {}
    for addr, code, _ in instructions:
        word_idx = addr // 8
        is_hi = (addr % 8) == 4
        if word_idx not in mem_words:
            mem_words[word_idx] = [0, 0]
        if is_hi:
            mem_words[word_idx][1] = code
        else:
            mem_words[word_idx][0] = code

    hex_path = os.path.join(out_dir, "program.hex")
    with open(hex_path, "w") as f:
        max_idx = max(mem_words.keys()) if mem_words else 0
        for i in range(max_idx + 1):
            lo, hi = mem_words.get(i, [0, 0])
            # 64-bit hex word in little-endian byte ordering {hi[31:0], lo[31:0]}
            val64 = (hi << 32) | lo
            f.write(f"{val64:016x}\n")
    print(f"Generated: {hex_path}")

    # 3. Intel HEX (.ihex) file (matching objcopy -O ihex)
    ihex_path = os.path.join(out_dir, "program.ihex")
    with open(ihex_path, "w") as f:
        # Extended linear address record for base 0x00000000
        f.write(":020000040000FA\n")
        for addr, code, _ in instructions:
            # 4 data bytes in little endian
            b0 = code & 0xFF
            b1 = (code >> 8) & 0xFF
            b2 = (code >> 16) & 0xFF
            b3 = (code >> 24) & 0xFF
            length = 4
            addr_lo = addr & 0xFFFF
            rec_type = 0 # Data record
            
            data = [length, (addr_lo >> 8) & 0xFF, addr_lo & 0xFF, rec_type, b0, b1, b2, b3]
            checksum = (~sum(data) + 1) & 0xFF
            line = f":{length:02X}{addr_lo:04X}{rec_type:02X}{b0:02X}{b1:02X}{b2:02X}{b3:02X}{checksum:02X}\n"
            f.write(line)
        # End of file record
        f.write(":00000001FF\n")
    print(f"Generated: {ihex_path}")

if __name__ == "__main__":
    prog = build_program()
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "firmware"
    write_hex_files(prog, target_dir)
