# WaveGuard SoC — Student Study Guide & Viva Preparation Notes
**Student ID**: 1602-23-735-045  
**Topic**: VeeR-EL2 RISC-V System-on-Chip (SoC) Design & Verification  
*(Written in simple, plain English to help you understand every part and ace your presentation/viva)*

---

## 1. The Big Picture: What Did We Actually Do?

Think of a computer or a smartphone chip. Inside, there is:
1. A **Brain (CPU)**: Western Digital **VeeR-EL2** (a 32-bit RISC-V processor).
2. A **Highway (Bus Interconnect)**: A 64-bit **AXI4 bus** that lets data move between the brain, memory, and devices.
3. A **Notebook (Memory)**: 32 KB Instruction Memory (IMEM) where code lives, and 32 KB Data Memory (DMEM) where variables and results live.
4. **Helpers (Peripherals / IPs)**:
   - 3 Standard helpers: **UART** (talks serial), **Standard Timer** (ticks like a clock), **GPIO** (switches pins on/off).
   - 4 Custom helpers: **DMA** (super-fast data mover), **CRC-32** (error detector), **Enhanced Timer** (stopwatch & watchdog supervisor), and **Seven-Segment Controller** (displays PASS/FAIL on screen/LEDs).

### What is the Main Story / Demo of Our Chip?
1. The CPU boots up from Instruction Memory and executes your mentor's C code: `add(10, 20)`. The answer `30` is calculated and saved in memory.
2. External data (the text `"123456789"`) comes in through the **UART** serial wire.
3. The **DMA Controller** catches this data, packs it into 64-bit words, and writes it directly into Data Memory without bothering the CPU.
4. The **CRC-32 Engine** reads this data from memory and computes an IEEE 802.3 checksum (`0xCBF43926`).
5. Because the checksum is correct, the CRC IP sends a direct 1-bit hardware signal to the **Seven-Segment Display**, lighting up the **PASS** LED!
6. Meanwhile, the **Enhanced Timer** acted like a stopwatch, measuring that DMA took 1,451 clock cycles and CRC took 20 cycles.

---

## 2. Walkthrough of Every Single IP (Block-by-Block)

### IP 1: VeeR-EL2 RISC-V Processor Core
- **What is it?** The main central processing unit (CPU).
- **What does it do?** Fetches instructions from memory, decodes them, executes mathematical calculations, and handles interrupts.
- **Key specs**:
  - Instruction set: **RV32IMC** (32-bit base integer, Multiplication/Division hardware, Compressed instructions).
  - Bus interface: 64-bit AXI4 master.

---

### IP 2: Standard Timer vs. Enhanced Timer (Crucial Viva Topic!)

| Feature | Standard Timer (`0x8000_5000`) | Enhanced Timer (`0x8000_2000`) |
|---|---|---|
| **What is it like?** | An ordinary alarm clock | A smart stopwatch + safety supervisor |
| **How does it work?** | Counts down from a number. When it hits zero, it fires an interrupt and reloads. | Physically wired to DMA & CRC status lines (`dma_active`, `crc_busy`). |
| **Does it know about other IPs?** | No. It is completely isolated. | **Yes.** It monitors when accelerators start and finish. |
| **Execution Profiling** | None. | **Measures exact hardware runtime** (e.g. DMA took 1451 cycles, CRC took 20 cycles). |
| **Safety / Watchdog** | None. | **Has hardware watchdogs**. If DMA hangs or freezes, it fires an alarm interrupt. |
| **Purpose** | Generates periodic operating system ticks (e.g. 1 ms tick). | System performance benchmarking and hang detection. |

---

### IP 3: DMA (Direct Memory Access) Controller (`0x8000_1000`)
- **What problem does it solve?** Normally, if 1,000 bytes come from UART, the CPU must wake up 1,000 times, execute a read instruction, and execute a write instruction. This wastes CPU time!
- **What does DMA do?** DMA is an autonomous memory mover. It takes the 8-bit stream from UART, packs 8 bytes into a 64-bit word inside an internal FIFO, and writes them directly into SRAM over the AXI4 bus. The CPU does zero work during data movement!
- **Key characteristics**:
  - Master on 64-bit AXI4 bus (AW, W, B channels).
  - Slave on 32-bit AXI-Lite bus (CPU configures source address, destination address, and transfer size).
  - Fires `irq_dma` when transfer finishes.

---

### IP 4: CRC-32 Accelerator Engine (`0x8000_0000`)
- **What is it?** Cyclic Redundancy Check error detection engine.
- **Why is it needed?** When data is sent over wireless, Ethernet, or stored on disks, bits can flip (corrupt). CRC computes a unique 32-bit fingerprint (checksum) using polynomial math ($0xEDB88320$).
- **How does it work in hardware?**
  - It has a 64-bit AXI4 Read Master. It reads data directly from memory.
  - Passes data byte-by-byte through a fast combinational XOR matrix.
  - Automatically compares the computed CRC with the expected CRC.
  - Asserts hardware flags: `crc_pass` or `crc_fail`, and triggers `irq_crc`.

---

### IP 5: UART Controller (`0x8000_4000`)
- **What does it do?** Universal Asynchronous Receiver-Transmitter. Converts parallel bytes inside the chip into a single-wire serial stream (`tx`), and receives serial data from the outside world (`rx`).
- **Key characteristics**:
  - Independent TX and RX paths.
  - Configurable baud rate divisor.
  - Built-in **Loopback Mode**: Software can connect TX directly to RX internally to test serial logic without plugging in any physical cables.
  - Direct 8-bit streaming connection to the DMA controller.

---

### IP 6: 32-bit GPIO Controller (`0x8000_6000`)
- **What is it?** General Purpose Input/Output.
- **What does it do?** Connects the chip to external physical pins (buttons, switches, external LEDs, sensors).
- **Key characteristics**:
  - 32 individual bidirectional pins.
  - Direction Register (`DIR`): `1` = Output pin, `0` = Input pin.
  - `DATA_OUT`: Values CPU drives onto the pins.
  - `DATA_IN`: Values CPU reads from external world.
  - **Edge Interrupts**: Can generate `irq_gpio` on rising edges (e.g. when an external user presses a pushbutton).

---

### IP 7: Seven-Segment Display Controller (`0x8000_3000`)
- **What is it?** Hardware decoder that drives 7-segment digital display cathodes/anodes and LEDs.
- **How does it work?**
  - Has two control modes:
    1. **Direct Hardware Override**: The CRC IP's `crc_pass` / `crc_fail` wires connect directly into this controller. If CRC passes, the hardware immediately displays `PASS` without CPU code!
    2. **Software CSR Mode**: The CPU can write to a register to manually display patterns.

---

## 3. Bus Architecture: AXI4 vs. AXI4-Lite

Why do we have two bus protocols in our SoC?
- **64-bit AXI4 (High-Speed Data Highway)**:
  - Connects CPU, Memory, DMA Write Master, and CRC Read Master.
  - Supports burst transfers (reading/writing multiple 64-bit words in a single transaction).
  - Used where high bandwidth is needed.
- **32-bit AXI4-Lite (Control Street)**:
  - Simplified, lightweight version of AXI.
  - No bursts (one 32-bit transfer at a time).
  - Perfect for reading and writing peripheral Control and Status Registers (CSRs) without wasting silicon area.
- **AXI4-to-AXI-Lite Bridge**:
  - The translator between the two. When the CPU wants to configure a peripheral at `0x8000_xxxx`, the bridge converts the 64-bit CPU request into a clean 32-bit AXI-Lite transaction.

---

## 4. Verification: What is a VIP and Why Did We Need It?

- **VIP = Verification IP**: A reusable verification module (BFM / Driver / Monitor) built to test bus protocols without writing manual bit-toggling code.
- **Unit Testing vs System Integration Testing**:
  - **Unit Testing (7 individual testbenches)**: Tests each IP alone. Proves that UART can receive bytes, DMA can pack bytes, and CRC can calculate checksums.
  - **System Integration Testing (`waveguard_soc_tb.sv`)**: Tests everything connected together. Proves that memory mapping works, interrupts reach the CPU, and data flows from UART $\rightarrow$ DMA $\rightarrow$ Memory $\rightarrow$ CRC $\rightarrow$ 7-Segment without deadlocks.

---

## 5. Top 8 Viva / Interview Questions & Model Answers

### Q1: What is the reset vector and memory layout of your SoC?
> *"The reset vector is `0x0000_0000` in Instruction Memory. Instruction Memory occupies `0x0000_0000` to `0x0000_7FFF` (32 KB). Data Memory occupies `0x0000_8000` to `0x0000_FFFF` (32 KB). Peripherals are mapped starting from `0x8000_0000` with 4 KB spaces allocated for CRC, DMA, Timers, 7-Segment, UART, and GPIO."*

### Q2: How did you execute the mentor's C code on the hardware?
> *"We compiled the bare-metal C program `int add(int a, int b) { return a + b; }` and startup assembly using RISC-V opcodes into a 64-bit `$readmemh` format (`program.hex`). The Instruction Memory preloads this file at boot. The CPU executes `add(10, 20)` and writes the result `30` (`0x1E`) into the Data Memory mailbox at `0x0000_8100`, which our testbench automatically verifies."*

### Q3: Why is DMA considered a Master and UART a Slave?
> *"UART is a slave on the bus because it only responds when the CPU reads or writes its registers. DMA is an AXI4 Master because it actively initiates write transactions to Memory across the bus on its own without needing the CPU to drive address or data wires."*

### Q4: How does CRC-32 differ from a simple parity check or checksum?
> *"A simple parity check only detects single-bit errors, and simple checksums fail to catch byte-reordering. CRC-32 treats data as a polynomial bit stream and divides it using Galois field arithmetic with the standard IEEE 802.3 polynomial ($0xEDB88320$). It detects all single-bit, double-bit, odd-numbered, and burst errors up to 32 bits with 99.999999% probability."*

### Q5: How did you test UART if you don't have physical hardware connected?
> *"Our UART IP features an internal Loopback mode where the transmitter output is internally routed into the receiver input. Additionally, our testbench includes a UART Serial VIP that simulates an external device transmitting serial bits at the programmed baud rate."*

### Q6: What happens if an external sensor sends data too fast for DMA?
> *"The DMA IP incorporates an asynchronous internal FIFO with flow control (`m_axis_tready`). If the FIFO approaches full, backpressure is exerted to throttle data ingestion until pending AXI write beats complete."*

### Q7: What are the two operating modes of the 7-Segment Controller?
> *"1. Hardware Override Mode: Directly triggered by the CRC accelerator's `crc_pass` and `crc_fail` status pins.  
2. Software Mode: Configured through AXI-Lite registers by the CPU."*

### Q8: What tools did you use to simulate and verify the design on Windows?
> *"We used Icarus Verilog (`iverilog 12.0`) for SystemVerilog IEEE-1800 compilation, VVP for simulation execution, Python 3 for firmware HEX generation, and GTKWave for cycle-accurate waveform viewing."*
