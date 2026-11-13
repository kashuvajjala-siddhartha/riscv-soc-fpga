// =============================================================================
// File        : dma_fifo.sv
// Project     : DMA IP — VeeR EL2 SoC Honours Project
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : Synchronous FIFO for the DMA UART receive buffer.
//
//   Differences from reference dma_fifo.sv:
//   - Reset is asynchronous active-low (rst_n) to match SoC convention.
//   - DATA_W defaults to 8 (byte-wide for UART path).
//   - DEPTH must be a power of 2 (enforced by ptr wrap using natural rollover).
//   - full/empty driven combinationally from count_r.
//   - Simultaneous read+write leaves count unchanged (pass-through semantic).
//   - rd_data is registered (one-cycle latency) with a read-enable handshake
//     so that downstream logic samples valid data exactly when rd_en is asserted
//     and empty is low.  The read pointer advances the cycle rd_en is asserted.
//
//   Read semantics (FWFT — first-word-fall-through):
//   rd_data reflects mem[rd_ptr] combinationally.  The consumer asserts rd_en
//   to consume the current head; rd_ptr advances on the same clock edge.
//
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module dma_fifo #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 16   // must be power of 2
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // Write port
    input  logic                    wr_en,
    input  logic [DATA_W-1:0]       wr_data,
    output logic                    full,

    // Read port — FWFT: rd_data is combinational from rd_ptr
    input  logic                    rd_en,
    output logic [DATA_W-1:0]       rd_data,
    output logic                    empty,

    // Status
    output logic [$clog2(DEPTH):0]  count
);

    // -------------------------------------------------------------------------
    // Pointer and storage
    // -------------------------------------------------------------------------
    localparam int PTR_W = $clog2(DEPTH);

    logic [DATA_W-1:0]       mem [0:DEPTH-1];
    logic [PTR_W-1:0]        wr_ptr;
    logic [PTR_W-1:0]        rd_ptr;
    logic [$clog2(DEPTH):0]  count_r;

    // -------------------------------------------------------------------------
    // Combinational status
    // -------------------------------------------------------------------------
    assign count  = count_r;
    assign full   = (count_r == DEPTH[$clog2(DEPTH):0]);
    assign empty  = (count_r == '0);

    // FWFT read data: combinational from current rd_ptr
    assign rd_data = mem[rd_ptr];

    // -------------------------------------------------------------------------
    // Effective handshake qualifiers
    // -------------------------------------------------------------------------
    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    // -------------------------------------------------------------------------
    // Write pointer
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_ptr <= '0;
        else if (do_wr)
            wr_ptr <= wr_ptr + 1'b1;  // natural rollover for power-of-2 DEPTH
    end

    // -------------------------------------------------------------------------
    // Read pointer
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rd_ptr <= '0;
        else if (do_rd)
            rd_ptr <= rd_ptr + 1'b1;
    end

    // -------------------------------------------------------------------------
    // Count
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_r <= '0;
        end else begin
            case ({do_wr, do_rd})
                2'b10:   count_r <= count_r + 1'b1;
                2'b01:   count_r <= count_r - 1'b1;
                default: count_r <= count_r;  // 00 or 11 (simultaneous: net zero)
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Memory write
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (do_wr)
            mem[wr_ptr] <= wr_data;
    end

endmodule : dma_fifo

`default_nettype wire
