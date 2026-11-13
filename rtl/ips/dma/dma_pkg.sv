// =============================================================================
// File        : dma_pkg.sv
// Project     : DMA IP — VeeR EL2 SoC Honours Project
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : Package for Stage 1 DMA (single-channel, 64-bit AXI4,
//               UART-to-memory).  Designed for our target architecture;
//               NOT a direct copy of the reference dma_pkg.sv (which is
//               32-bit, 4-channel).
//
// Clocking assumption
// -------------------
//   All signals (UART RX stream, AXI4-Lite, AXI4 write master) are
//   synchronous to the same clock (clk) and reset (rst_n).  If the UART
//   deserialiser runs at a different clock domain, the caller must insert
//   a CDC FIFO before connecting uart_rx_data/valid to this IP.  Within
//   this IP, no asynchronous paths are present.
// =============================================================================

`default_nettype none

package dma_pkg;

    // -------------------------------------------------------------------------
    // Global parameters — override at instantiation as needed
    // -------------------------------------------------------------------------
    parameter int DMA_DATA_W        = 64;   // AXI4 write-data width (bits)
    parameter int DMA_ADDR_W        = 32;   // AXI4 address width (bits)
    parameter int DMA_FIFO_DEPTH    = 16;   // UART receive FIFO depth (bytes)

    // -------------------------------------------------------------------------
    // AXI4 response codes
    // -------------------------------------------------------------------------
    localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
    localparam logic [1:0] AXI_RESP_EXOKAY = 2'b01;
    localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
    localparam logic [1:0] AXI_RESP_DECERR = 2'b11;

    // -------------------------------------------------------------------------
    // AXI4 constant attribute values used by the DMA write master
    // -------------------------------------------------------------------------
    localparam logic [2:0] AXI_AWSIZE_8B  = 3'b011; // 8 bytes per beat
    localparam logic [1:0] AXI_BURST_INCR = 2'b01;  // incrementing burst
    localparam logic [1:0] AXI_BURST_FIXED= 2'b00;  // fixed (unused)
    localparam logic [3:0] AXI_CACHE_NORM = 4'b0011; // normal non-cacheable bufferable
    localparam logic [2:0] AXI_PROT_UNPRIV= 3'b000; // unprivileged, non-secure, data

    // -------------------------------------------------------------------------
    // DMA FSM state encoding (Stage 1)
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        DMA_IDLE    = 3'd0,  // waiting for START
        DMA_ACTIVE  = 3'd1,  // collecting bytes and issuing writes
        DMA_FLUSH   = 3'd2,  // final partial word in flight
        DMA_DONE    = 3'd3,  // transfer complete — pulse done_sticky
        DMA_ERROR   = 3'd4   // error — pulse error_sticky
    } dma_state_t;

    // -------------------------------------------------------------------------
    // Write engine FSM state encoding
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        WR_IDLE = 2'd0,  // waiting for a packed word
        WR_ADDR = 2'd1,  // issuing AW (and W simultaneously)
        WR_RESP = 2'd2   // waiting for B channel
    } wr_state_t;

endpackage : dma_pkg

`default_nettype wire
