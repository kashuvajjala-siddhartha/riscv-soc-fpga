// =============================================================================
// File        : crc32_byte_core.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : CRC-32/Ethernet byte-parallel processing core.
//
//   Processes one byte per clock cycle using a combinational XOR tree that
//   unrolls the reflected LFSR algorithm 8 times.  The result is registered
//   at the output.
//
//   Algorithm: CRC-32/Ethernet
//     Poly     = 0x04C11DB7  (normal form)
//     Init     = 0xFFFFFFFF
//     RefIn    = 1  → bytes processed LSB-first
//     RefOut   = 1  → output register is the reflected accumulator
//     XorOut   = 0xFFFFFFFF
//     Check    = 0xCBF43926  (CRC of "123456789")
//
//   Implementation uses the reflected polynomial 0xEDB88320 with a
//   right-shifting register, which is equivalent to processing reflected
//   input with the normal polynomial.
//
//   Interface:
//     clk       : system clock (rising edge)
//     rst_n     : active-low synchronous reset
//     init_i    : synchronous initialise — loads INIT value on next clock
//     valid_i   : data_i is valid; CRC is updated on next clock
//     data_i    : 8-bit input data byte
//     crc_o     : 32-bit CRC output (updated one cycle after valid_i)
//                 Includes FINAL_XOR.  Valid immediately after init_i
//                 de-asserts and valid_i asserts.
//     crc_raw_o : CRC register without final XOR (for chaining)
//
// Reference architecture: Brendan Lynskey 2025 (MIT licence)
//   https://github.com/BrendanJamesLynskey/CRC  (crc_parallel_xor.sv)
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module crc32_byte_core
  import crc32_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,      // active-low synchronous reset

  // Control
  input  logic        init_i,     // synchronous initialise (load CRC32_INIT)
  input  logic        valid_i,    // data_i is valid this cycle

  // Data
  input  logic [7:0]  data_i,     // input byte (LSB = first bit processed)

  // Results
  output logic [31:0] crc_o,      // CRC output with final XOR applied
  output logic [31:0] crc_raw_o   // CRC register without final XOR
);

  // ---------------------------------------------------------------------------
  // Internal CRC register (accumulates the reflected intermediate state)
  // ---------------------------------------------------------------------------
  logic [31:0] crc_reg;

  // ---------------------------------------------------------------------------
  // Combinational XOR-tree: compute next CRC state from current state + byte
  //
  // This is the unrolled reflected algorithm:
  //   - Right-shifting register
  //   - Reflected polynomial 0xEDB88320 (= reflect(0x04C11DB7))
  //   - Input byte processed LSB-first
  //
  // Unrolling 8 iterations of the bit-serial reflected LFSR:
  //   for i = 0 to 7:
  //     feedback = crc[0] ^ data[i]
  //     crc = (crc >> 1) ^ (feedback ? 0xEDB88320 : 0)
  //
  // The function is computed purely combinationally from current crc_reg and
  // data_i.  The result is clocked into crc_reg on valid_i.
  // ---------------------------------------------------------------------------

  function automatic logic [31:0] crc32_next (
    input logic [31:0] crc_in,
    input logic [7:0]  data_byte
  );
    logic [31:0] c;
    logic        fb;
    c = crc_in;
    for (int i = 0; i < 8; i++) begin
      fb = c[0] ^ data_byte[i];
      c  = {1'b0, c[31:1]};
      if (fb) c = c ^ CRC32_POLY_REF;
    end
    return c;
  endfunction

  // ---------------------------------------------------------------------------
  // Sequential logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      crc_reg <= CRC32_INIT;
    end else if (init_i) begin
      crc_reg <= CRC32_INIT;
    end else if (valid_i) begin
      crc_reg <= crc32_next(crc_reg, data_i);
    end
  end

  // ---------------------------------------------------------------------------
  // Output assignments
  // ---------------------------------------------------------------------------
  assign crc_raw_o = crc_reg;
  assign crc_o     = crc_reg ^ CRC32_FINAL_XOR;

endmodule : crc32_byte_core

`default_nettype wire
