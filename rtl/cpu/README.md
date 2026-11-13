# RISC-V Processor Core Interface (CHIPS Alliance VeeR-EL2)

## Overview
This SoC architecture is designed around the **VeeR-EL2** (Western Digital / CHIPS Alliance) 32-bit RISC-V core:
- **ISA**: RV32IMC (Base Integer 32-bit, Integer Multiplication/Division, Compressed Instructions).
- **Pipeline**: High-performance superscalar, 4-stage dual-issue pipeline.
- **Bus Interface**: 64-bit AXI4 Master interface supporting decoupled Instruction Fetch Unit (IFU) and Load-Store Unit (LSU) buses.
- **Official Upstream Repository**: [https://github.com/chipsalliance/Cores-VeeR-EL2.git](https://github.com/chipsalliance/Cores-VeeR-EL2.git)

## System-on-Chip Pinout Integration
In `rtl/soc/waveguard_soc_top.sv`, the CPU connects to the system fabric through:
1. **Instruction Fetch Unit (IFU)**: 64-bit AXI4 read-only port mapped to low memory (`0x0000_0000 - 0x0000_7FFF`).
2. **Load Store Unit (LSU)**: 64-bit AXI4 read/write port accessing both SRAM Data Memory (`0x0000_8000 - 0x0000_FFFF`) and the peripheral memory map via the AXI4-Lite bridge (`0x8000_0000 - 0x8000_6FFF`).
3. **Dedicated Interrupt Inputs**:
   - `irq_dma`: Asserted on DMA transfer completion or bus fault.
   - `irq_crc`: Asserted on CRC-32 completion or checksum failure.
   - `irq_timer_std`: Standard timer periodic interrupt.
   - `irq_timer_enh`: Enhanced timer profiling match and watchdog timeout.
   - `irq_gpio`: Edge-triggered input pin interrupts.
