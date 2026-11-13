// =============================================================================
// File        : crc32_pkg.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : Package containing all CRC-32 algorithm constants, register
//               map offsets, and shared type definitions for the CRC-32 IP.
//
// CRC-32/Ethernet algorithm parameters (as per CRC RevEng catalogue):
//   Width    : 32
//   Poly     : 0x04C11DB7
//   Init     : 0xFFFFFFFF
//   RefIn    : true  (reflected input bytes)
//   RefOut   : true  (reflected output)
//   XorOut   : 0xFFFFFFFF
//   Check    : 0xCBF43926  (CRC of ASCII "123456789")
//
// Reference   : Based on CRC architecture by Brendan Lynskey 2025 (MIT licence)
//               https://github.com/BrendanJamesLynskey/CRC
// =============================================================================

`ifndef CRC32_PKG_SV
`define CRC32_PKG_SV

package crc32_pkg;

  // ---------------------------------------------------------------------------
  // CRC-32/Ethernet algorithm constants
  // ---------------------------------------------------------------------------

  // Generator polynomial (normal/MSB-first form, implicit leading x^32 term)
  localparam logic [31:0] CRC32_POLY      = 32'h04C11DB7;

  // Reflected polynomial — precomputed for use in right-shifting implementation
  // reflect(0x04C11DB7) = 0xEDB88320
  localparam logic [31:0] CRC32_POLY_REF  = 32'hEDB88320;

  // Initial CRC register value
  localparam logic [31:0] CRC32_INIT      = 32'hFFFFFFFF;

  // Final XOR applied to the CRC register before output
  localparam logic [31:0] CRC32_FINAL_XOR = 32'hFFFFFFFF;

  // RefIn = 1, RefOut = 1 — use reflected (right-shifting) algorithm
  localparam bit          CRC32_REFLECT   = 1'b1;

  // Known check value: CRC-32 of ASCII "123456789" (0x31 ... 0x39)
  localparam logic [31:0] CRC32_CHECK     = 32'hCBF43926;

  // ---------------------------------------------------------------------------
  // Register map — peripheral-relative byte offsets
  // NOTE: Absolute base address is assigned at SoC integration time.
  // ---------------------------------------------------------------------------

  // CONTROL register (RW) : offset 0x00
  //   Bit 0 : START  — write 1 to start CRC calculation; auto-clears when busy
  //   Bit 1 : IE     — interrupt enable (mirrors IRQ_ENABLE.IE for convenience)
  //   Bit 2 : RESET  — write 1 to software-reset the IP; auto-clears
  //   [31:3] : reserved, read as 0, ignore on write
  localparam logic [7:0] REG_CONTROL      = 8'h00;

  // STATUS register (RO) : offset 0x04
  //   Bit 0 : BUSY   — 1 while CRC calculation is in progress
  //   Bit 1 : DONE   — 1 when calculation has completed (cleared by START)
  //   Bit 2 : PASS   — 1 if computed CRC == expected CRC (valid only when DONE)
  //   Bit 3 : FAIL   — 1 if computed CRC != expected CRC (valid only when DONE)
  //   Bit 4 : ERROR  — 1 if AXI read returned SLVERR or DECERR
  //   [31:5] : reserved
  localparam logic [7:0] REG_STATUS       = 8'h04;

  // SRC_ADDR_LO register (RW) : offset 0x08
  //   [31:0] : source memory address bits [31:0]
  //   NOTE: The AXI read master uses a 32-bit address (matching interconnect
  //   ADDR_WIDTH=32). SRC_ADDR_HI is provided for future 64-bit address
  //   extension but currently drives no hardware logic.
  localparam logic [7:0] REG_SRC_ADDR_LO  = 8'h08;

  // SRC_ADDR_HI register (RW) : offset 0x0C
  //   [31:0] : source memory address bits [63:32] (reserved for future use)
  localparam logic [7:0] REG_SRC_ADDR_HI  = 8'h0C;

  // LENGTH register (RW) : offset 0x10
  //   [31:0] : number of bytes to read and CRC
  //   Writing 0 is legal; STATUS.DONE is set immediately with PASS/FAIL
  //   based on comparing 0xFFFFFFFF ^ 0xFFFFFFFF = 0x00000000 against EXPECTED
  localparam logic [7:0] REG_LENGTH       = 8'h10;

  // EXPECTED_CRC register (RW) : offset 0x14
  //   [31:0] : expected CRC-32 value for comparison
  localparam logic [7:0] REG_EXPECTED_CRC = 8'h14;

  // COMPUTED_CRC register (RO) : offset 0x18
  //   [31:0] : computed CRC-32 result (valid only when STATUS.DONE == 1)
  localparam logic [7:0] REG_COMPUTED_CRC = 8'h18;

  // IRQ_ENABLE register (RW) : offset 0x1C
  //   Bit 0 : IE — 1 to enable completion interrupt output
  //   [31:1] : reserved
  localparam logic [7:0] REG_IRQ_ENABLE   = 8'h1C;

  // IRQ_STATUS register (R/W1C) : offset 0x20
  //   Bit 0 : DONE_IRQ — 1 when calculation completed and IE==1
  //                      Write 1 to clear (write-one-to-clear)
  //   [31:1] : reserved
  localparam logic [7:0] REG_IRQ_STATUS   = 8'h20;

  // ---------------------------------------------------------------------------
  // CONTROL register bit positions
  // ---------------------------------------------------------------------------
  localparam int unsigned CTRL_START_BIT  = 0;
  localparam int unsigned CTRL_IE_BIT     = 1;
  localparam int unsigned CTRL_RESET_BIT  = 2;

  // ---------------------------------------------------------------------------
  // STATUS register bit positions
  // ---------------------------------------------------------------------------
  localparam int unsigned STAT_BUSY_BIT   = 0;
  localparam int unsigned STAT_DONE_BIT   = 1;
  localparam int unsigned STAT_PASS_BIT   = 2;
  localparam int unsigned STAT_FAIL_BIT   = 3;
  localparam int unsigned STAT_ERROR_BIT  = 4;

  // ---------------------------------------------------------------------------
  // IRQ_STATUS register bit positions
  // ---------------------------------------------------------------------------
  localparam int unsigned IRQ_DONE_BIT    = 0;

  // ---------------------------------------------------------------------------
  // AXI response codes
  // ---------------------------------------------------------------------------
  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
  localparam logic [1:0] AXI_RESP_DECERR = 2'b11;

  // ---------------------------------------------------------------------------
  // Controller state machine type
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    CRC_IDLE    = 3'b000,  // Waiting for START
    CRC_FETCH   = 3'b001,  // Issuing AXI read requests
    CRC_PROCESS = 3'b010,  // Processing received read data
    CRC_DONE    = 3'b011,  // Calculation complete, results latched
    CRC_ERROR   = 3'b100   // AXI error response received
  } crc_state_t;

endpackage : crc32_pkg

`endif // CRC32_PKG_SV
