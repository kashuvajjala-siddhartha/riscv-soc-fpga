// =============================================================================
// File        : crc32_axi_read_master.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : AXI4 read master for the CRC-32 IP.
//
//   Reads a contiguous memory region specified by base_addr_i and byte_count_i
//   through a 64-bit AXI4 read channel, then delivers each valid byte to the
//   CRC engine through a simple byte-stream interface.
//
//   Data path widths:
//     AXI data bus : 64 bits  (matches SoC interconnect DATA_WIDTH=64)
//     AXI address  : 32 bits  (matches SoC interconnect ADDR_WIDTH=32)
//     AXI ID       : 8 bits   (matches SoC interconnect ID_WIDTH=8)
//     CRC stream   : 8 bits   per byte
//
//   Operation:
//     1. On start_i: capture base_addr_i and byte_count_i, issue AXI AR.
//     2. Each burst reads up to MAX_BURST_LEN beats of 8 bytes.
//     3. For each read beat: deliver valid bytes one at a time via
//        byte_data_o / byte_valid_o, gated by byte_ready_i backpressure.
//     4. Track bytes remaining.  When all bytes delivered: assert done_o.
//     5. On AXI SLVERR/DECERR: assert error_o.
//
//   The state machine is:
//     IDLE    → AR      (on start_i, non-zero byte_count_i)
//     IDLE    → DONE    (on start_i, zero byte_count_i)
//     AR      → RDATA   (AR accepted)
//     RDATA   → EXTRACT (R beat received)
//     EXTRACT → RDATA   (byte emitted, more beats remain in burst)
//     EXTRACT → AR      (burst exhausted, bytes remain)
//     EXTRACT → DONE    (all bytes delivered)
//     DONE    → IDLE
//     ERROR   → IDLE
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module crc32_axi_read_master
  import crc32_pkg::*;
#(
  parameter int unsigned ADDR_WIDTH    = 32,
  parameter int unsigned ID_WIDTH      = 8,
  parameter int unsigned MAX_BURST_LEN = 16
)(
  input  logic                    clk,
  input  logic                    rst_n,

  // --------------------------------------------------------------------------
  // Control interface
  // --------------------------------------------------------------------------
  input  logic                    start_i,
  input  logic [ADDR_WIDTH-1:0]   base_addr_i,
  input  logic [31:0]             byte_count_i,
  output logic                    done_o,
  output logic                    error_o,

  // --------------------------------------------------------------------------
  // CRC byte stream output
  // --------------------------------------------------------------------------
  output logic [7:0]              byte_data_o,
  output logic                    byte_valid_o,
  input  logic                    byte_ready_i,

  // --------------------------------------------------------------------------
  // AXI4 Read Master Interface
  // --------------------------------------------------------------------------
  output logic [ID_WIDTH-1:0]     m_axi_arid,
  output logic [ADDR_WIDTH-1:0]   m_axi_araddr,
  output logic [7:0]              m_axi_arlen,
  output logic [2:0]              m_axi_arsize,
  output logic [1:0]              m_axi_arburst,
  output logic                    m_axi_arlock,
  output logic [3:0]              m_axi_arcache,
  output logic [2:0]              m_axi_arprot,
  output logic [3:0]              m_axi_arqos,
  output logic                    m_axi_arvalid,
  input  logic                    m_axi_arready,

  input  logic [ID_WIDTH-1:0]     m_axi_rid,
  input  logic [63:0]             m_axi_rdata,
  input  logic [1:0]              m_axi_rresp,
  input  logic                    m_axi_rlast,
  input  logic                    m_axi_rvalid,
  output logic                    m_axi_rready
);

  // --------------------------------------------------------------------------
  // Local constants
  // --------------------------------------------------------------------------
  localparam int BYTES_PER_BEAT  = 8;
  localparam int BEAT_ADDR_BITS  = 3;   // log2(8)

  // --------------------------------------------------------------------------
  // State machine
  // --------------------------------------------------------------------------
  typedef enum logic [2:0] {
    RM_IDLE    = 3'b000,
    RM_AR      = 3'b001,
    RM_RDATA   = 3'b010,
    RM_EXTRACT = 3'b011,
    RM_DONE    = 3'b100,
    RM_ERROR   = 3'b101
  } rm_state_t;

  rm_state_t state;

  // --------------------------------------------------------------------------
  // Registers — all driven by a single always_ff block
  // --------------------------------------------------------------------------
  logic [ADDR_WIDTH-1:0]  cur_addr;          // current AXI AR address (8-byte aligned)
  logic [31:0]            bytes_remaining;   // bytes still to deliver to CRC
  logic [2:0]             skip_bytes;        // leading bytes to discard (alignment)

  logic [63:0]            beat_buf;          // captured 64-bit read beat
  logic [2:0]             byte_idx;          // index of next byte to emit from beat_buf
  logic [3:0]             valid_in_beat;     // valid byte count in beat_buf

  logic [8:0]             burst_beats_rem;   // beats remaining in current AXI burst
  logic [8:0]             cur_burst_len;     // burst length issued for current AR

  logic                   ar_valid_r;        // AR valid registered
  logic                   error_r;           // error latch

  // --------------------------------------------------------------------------
  // Combinational helpers
  // --------------------------------------------------------------------------

  // Align address DOWN to 8-byte boundary
  wire [ADDR_WIDTH-1:0] aligned_base =
      {base_addr_i[ADDR_WIDTH-1:BEAT_ADDR_BITS], {BEAT_ADDR_BITS{1'b0}}};

  // Number of leading bytes to skip in first beat
  wire [2:0] lead_skip = base_addr_i[BEAT_ADDR_BITS-1:0];

  // Calculate burst beat count from remaining bytes + alignment skip
  // ceil((bytes_remaining + skip) / 8), capped at MAX_BURST_LEN
  function automatic logic [8:0] calc_burst(
    input logic [31:0] remain,
    input logic [2:0]  skip
  );
    logic [32:0] total;
    logic [8:0]  beats;
    total = {1'b0, remain} + {30'b0, skip};
    beats = total[32:3] + (|total[2:0] ? 9'd1 : 9'd0);
    if (beats > MAX_BURST_LEN[8:0]) beats = MAX_BURST_LEN[8:0];
    if (beats == 9'd0)               beats = 9'd1;
    return beats;
  endfunction

  // Valid bytes in an incoming beat
  // (all 8 except: first beat may have leading skip, last beat may be partial)
  function automatic logic [3:0] beat_valid_count(
    input logic [31:0] remain,
    input logic [2:0]  skip
  );
    logic [3:0] avail;  // bytes available in this beat after skip
    logic [3:0] vb;
    avail = 4'(BYTES_PER_BEAT) - {1'b0, skip};
    if (remain <= {28'b0, avail})
      vb = remain[3:0];
    else
      vb = avail;
    return vb;
  endfunction

  // --------------------------------------------------------------------------
  // Single always_ff — all state and datapath in one block
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state            <= RM_IDLE;
      cur_addr         <= '0;
      bytes_remaining  <= '0;
      skip_bytes       <= '0;
      beat_buf         <= '0;
      byte_idx         <= '0;
      valid_in_beat    <= '0;
      burst_beats_rem  <= '0;
      cur_burst_len    <= '0;
      ar_valid_r       <= 1'b0;
      error_r          <= 1'b0;
    end else begin
      case (state)

        // ------------------------------------------------------------------
        RM_IDLE: begin
          error_r    <= 1'b0;
          ar_valid_r <= 1'b0;
          if (start_i) begin
            if (byte_count_i == 32'b0) begin
              state <= RM_DONE;
            end else begin
              cur_addr        <= aligned_base;
              bytes_remaining <= byte_count_i;
              skip_bytes      <= lead_skip;
              // Pre-compute burst length for first AR
              cur_burst_len   <= calc_burst(byte_count_i, lead_skip);
              ar_valid_r      <= 1'b1;
              state           <= RM_AR;
            end
          end
        end

        // ------------------------------------------------------------------
        RM_AR: begin
          // Hold AR valid until accepted
          if (ar_valid_r && m_axi_arready) begin
            ar_valid_r <= 1'b0;
            burst_beats_rem <= cur_burst_len;
            state <= RM_RDATA;
          end
        end

        // ------------------------------------------------------------------
        RM_RDATA: begin
          if (m_axi_rvalid) begin
            // Capture beat
            beat_buf      <= m_axi_rdata;
            byte_idx      <= skip_bytes;
            valid_in_beat <= beat_valid_count(bytes_remaining, skip_bytes);

            if (m_axi_rresp != AXI_RESP_OKAY) begin
              error_r <= 1'b1;
              state   <= RM_ERROR;
            end else begin
              state <= RM_EXTRACT;
            end
            burst_beats_rem <= burst_beats_rem - 9'd1;
          end
        end

        // ------------------------------------------------------------------
        RM_EXTRACT: begin
          // Emit one byte per cycle when ready
          if (byte_ready_i) begin
            logic [3:0] last_idx;
            last_idx = {1'b0, skip_bytes} + valid_in_beat - 4'd1;

            if (byte_idx == last_idx[2:0]) begin
              // Last valid byte of this beat consumed
              bytes_remaining <= bytes_remaining - {28'b0, valid_in_beat};
              skip_bytes      <= 3'b0;  // skip only applies to first beat

              if (bytes_remaining == {28'b0, valid_in_beat}) begin
                // All bytes delivered
                state <= RM_DONE;
              end else if (burst_beats_rem == 9'd0) begin
                // Need a new burst
                logic [31:0] rem_after;
                logic [2:0]  new_skip;
                rem_after = bytes_remaining - {28'b0, valid_in_beat};
                new_skip  = 3'b0;
                cur_addr  <= cur_addr + ({23'b0, cur_burst_len} << BEAT_ADDR_BITS);
                cur_burst_len <= calc_burst(rem_after, new_skip);
                ar_valid_r    <= 1'b1;
                state         <= RM_AR;
              end else begin
                // More beats in this burst
                state <= RM_RDATA;
              end
            end else begin
              byte_idx <= byte_idx + 3'b1;
            end
          end
        end

        // ------------------------------------------------------------------
        RM_DONE: begin
          state <= RM_IDLE;
        end

        // ------------------------------------------------------------------
        RM_ERROR: begin
          state <= RM_IDLE;
        end

        default: state <= RM_IDLE;

      endcase
    end
  end

  // --------------------------------------------------------------------------
  // AXI AR channel — driven from ar_valid_r register
  // --------------------------------------------------------------------------
  assign m_axi_arid    = '0;
  assign m_axi_araddr  = cur_addr;
  assign m_axi_arlen   = 8'(cur_burst_len - 9'd1);
  assign m_axi_arsize  = 3'b011;    // 8 bytes per beat
  assign m_axi_arburst = 2'b01;    // INCR
  assign m_axi_arlock  = 1'b0;
  assign m_axi_arcache = 4'b0000;
  assign m_axi_arprot  = 3'b000;
  assign m_axi_arqos   = 4'b0000;
  assign m_axi_arvalid = ar_valid_r;

  // --------------------------------------------------------------------------
  // AXI R channel — accept when in RDATA state
  // --------------------------------------------------------------------------
  assign m_axi_rready = (state == RM_RDATA);

  // --------------------------------------------------------------------------
  // Byte stream output — valid when in EXTRACT state
  // --------------------------------------------------------------------------
  assign byte_valid_o = (state == RM_EXTRACT) && byte_ready_i;
  assign byte_data_o  = beat_buf[byte_idx * 8 +: 8];

  // --------------------------------------------------------------------------
  // Status outputs — sticky until next start_i or reset
  // done_o and error_o are held high after completion so the controller
  // and testbench can sample them without cycle-accurate alignment.
  // --------------------------------------------------------------------------
  logic done_r;
  logic error_r_out;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      done_r      <= 1'b0;
      error_r_out <= 1'b0;
    end else if (start_i) begin
      done_r      <= 1'b0;
      error_r_out <= 1'b0;
    end else begin
      if (state == RM_DONE)  done_r      <= 1'b1;
      if (state == RM_ERROR) error_r_out <= 1'b1;
    end
  end

  assign done_o  = done_r  | (state == RM_DONE);
  assign error_o = error_r_out | (state == RM_ERROR);

endmodule : crc32_axi_read_master

`default_nettype wire
