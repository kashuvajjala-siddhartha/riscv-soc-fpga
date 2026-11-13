# Verification IPs (VIPs)

This directory contains the verification infrastructure used to test the WaveGuard SoC and its individual peripheral blocks.

## 1. Native SystemVerilog VIPs (Windows & Icarus Verilog)
To enable zero-dependency simulation with Icarus Verilog on Windows, native SystemVerilog Bus Functional Models (BFMs) and protocol responders are embedded directly in the testbenches:

- **AXI4-Lite Master BFM**:
  - Located in: `tb/soc/waveguard_soc_tb.sv` and `tb/unit_tests/`
  - Provides high-level `write_reg(addr, data)` and `read_reg(addr, data)` tasks.
  - Implements strict 5-channel AXI4-Lite handshake checking, response verification (`BRESP`, `RRESP`), and decoupled address/data transaction handling.

- **64-bit AXI4 Slave Memory VIP**:
  - Located in: `tb/unit_tests/tb_crc32_unit.sv` and `tb/unit_tests/tb_dma_unit.sv`
  - Emulates 64-bit multi-beat burst memory (read master bursts for CRC-32 and write master bursts for DMA).
  - Features configurable response delay and error injection (`inject_err` asserts `SLVERR` to verify IP fault handling).

- **UART Serial Driver & Monitor VIP**:
  - Located in: `tb/unit_tests/tb_uart_unit.sv` and `tb/soc/waveguard_soc_tb.sv`
  - Converts parallel test bytes into asynchronous serial frames (Start bit, 8 data bits LSB-first, Stop bit) at configured baud rates.
  - Monitors the serial TX line, reconstructs bytes, and flags framing/baud discrepancies.

- **CRC-32 Golden Reference Model**:
  - Software algorithmic model computing the IEEE 802.3 Ethernet polynomial ($0xEDB88320$).
  - Evaluates data payloads concurrently during simulation and compares with the hardware accelerator register bitfields.

## 2. Complete UVM 1.2 VIP Suite (Synopsys VCS / Commercial Simulators)
The `tb/vip/uvm/` directory contains an enterprise-grade Universal Verification Methodology (UVM 1.2) suite:
- `agents/axi_lite/`: Contains `axi_lite_agent.sv`, `axi_lite_driver.sv`, `axi_lite_monitor.sv`, `axi_lite_sequencer.sv`, and `axi_lite_transaction.sv`.
- `agents/axi_read/`: Contains `axi_read_memory_model.sv` (UVM burst memory slave).
- `env/`: Complete UVM environment wiring agents, coverage models, and scoreboards.
- `sequences/`: Directed and constrained-random stimulus sequences.
- `tests/`: UVM test definitions.
- `run_verification.sh`: Execution script for VCS/Verdi.
