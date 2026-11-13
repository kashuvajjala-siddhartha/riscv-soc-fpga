// =============================================================================
// File        : dma_uart_to_mem.sv
// Project     : DMA IP — VeeR EL2 SoC Honours Project
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : Stage 1 DMA — UART byte stream to external memory.
//
//   Data path:
//     UART RX → 8-bit FIFO → 64-bit byte packer → AXI4 write master → Memory
//
//   Control interface : AXI4-Lite slave (32-bit data, parameterized address)
//   Data interface    : AXI4 write master (64-bit data, parameterized address)
//   UART interface    : synchronous valid/ready handshake
//
// Clocking assumption
// -------------------
//   All interfaces (AXI4-Lite, AXI4 write master, UART RX stream) are
//   synchronous to the same rising-edge clock (clk) and same active-low
//   asynchronous reset (rst_n).  If the UART demodulator runs in a separate
//   clock domain, a CDC synchroniser FIFO must be inserted upstream of the
//   uart_rx_* ports.
//
// Reset convention
// ----------------
//   Asynchronous active-low (negedge rst_n).  All registered state cleared.
//
// Single-owner rule
// -----------------
//   Every register is driven by exactly one always_ff block.
//   Three always_ff blocks exist:
//     1. axil_ff  — AXI4-Lite registers (hold latches, response, cfg regs).
//                   Generates: start_req_r, clear_done_r, clear_error_r pulses.
//     2. wr_ff    — AXI4 write-engine state (wr_state, aw_done_r, w_done_r,
//                   wr_data_r, wr_strb_r, wr_addr_r).
//     3. dma_ff   — Everything else: DMA FSM, byte packer, count, sticky flags.
//                   Reads start_req_r / clear_* from axil_ff.
//                   Reads wr_state from wr_ff (combinationally) for feedback.
//
// Register Map (AXI4-Lite byte offsets)
// --------------------------------------
//   0x00  CTRL      [0]  ENABLE     (RW)
//                   [1]  START      (WO, self-clearing; reads as 0)
//                   [2]  IRQ_ENABLE (RW)
//   0x04  STATUS    [0]  BUSY       (RO)
//                   [1]  DONE       (RO, W1C)
//                   [2]  ERROR      (RO, W1C)
//   0x08  DST_LO    [31:0]  Destination address bits [31:0]
//   0x0C  DST_HI    [31:0]  Destination address bits [63:32]
//                           (writable only if ADDR_W > 32; always readable)
//   0x10  LENGTH    [31:0]  Transfer length in bytes (must be > 0)
//   0x14  COUNT     [31:0]  Bytes committed to memory  (RO)
//
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module dma_uart_to_mem
  import dma_pkg::*;
#(
    parameter int ADDR_W     = 32,   // AXI address width (bits)
    parameter int FIFO_DEPTH = 16    // UART receive FIFO depth (bytes; power of 2)
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // -------------------------------------------------------------------------
    // AXI4-Lite slave — 32-bit data
    // -------------------------------------------------------------------------
    input  logic [ADDR_W-1:0]     s_axil_awaddr,
    input  logic [2:0]            s_axil_awprot,
    input  logic                  s_axil_awvalid,
    output logic                  s_axil_awready,

    input  logic [31:0]           s_axil_wdata,
    input  logic [3:0]            s_axil_wstrb,
    input  logic                  s_axil_wvalid,
    output logic                  s_axil_wready,

    output logic [1:0]            s_axil_bresp,
    output logic                  s_axil_bvalid,
    input  logic                  s_axil_bready,

    input  logic [ADDR_W-1:0]     s_axil_araddr,
    input  logic [2:0]            s_axil_arprot,
    input  logic                  s_axil_arvalid,
    output logic                  s_axil_arready,

    output logic [31:0]           s_axil_rdata,
    output logic [1:0]            s_axil_rresp,
    output logic                  s_axil_rvalid,
    input  logic                  s_axil_rready,

    // -------------------------------------------------------------------------
    // UART RX byte stream (synchronous to clk — see clocking assumption)
    // -------------------------------------------------------------------------
    input  logic [7:0]            uart_rx_data,
    input  logic                  uart_rx_valid,
    output logic                  uart_rx_ready,

    // -------------------------------------------------------------------------
    // AXI4 write master — 64-bit data
    // -------------------------------------------------------------------------
    output logic [ADDR_W-1:0]     m_axi_awaddr,
    output logic [7:0]            m_axi_awlen,
    output logic [2:0]            m_axi_awsize,
    output logic [1:0]            m_axi_awburst,
    output logic                  m_axi_awlock,
    output logic [3:0]            m_axi_awcache,
    output logic [2:0]            m_axi_awprot,
    output logic [3:0]            m_axi_awqos,
    output logic                  m_axi_awvalid,
    input  logic                  m_axi_awready,

    output logic [63:0]           m_axi_wdata,
    output logic [7:0]            m_axi_wstrb,
    output logic                  m_axi_wlast,
    output logic                  m_axi_wvalid,
    input  logic                  m_axi_wready,

    input  logic [1:0]            m_axi_bresp,
    input  logic                  m_axi_bvalid,
    output logic                  m_axi_bready,

    // -------------------------------------------------------------------------
    // Status outputs
    // -------------------------------------------------------------------------
    output logic                  dma_active,
    output logic                  dma_done,
    output logic                  dma_error,
    output logic                  irq_o
);

    // =========================================================================
    // Register-map address constants (compare against addr[7:0])
    // =========================================================================
    localparam logic [7:0] REG_CTRL   = 8'h00;
    localparam logic [7:0] REG_STATUS = 8'h04;
    localparam logic [7:0] REG_DST_LO = 8'h08;
    localparam logic [7:0] REG_DST_HI = 8'h0C;
    localparam logic [7:0] REG_LENGTH = 8'h10;
    localparam logic [7:0] REG_COUNT  = 8'h14;

    // =========================================================================
    // DMA / write-engine state types
    // =========================================================================
    typedef enum logic [2:0] {
        DMA_IDLE   = 3'd0,
        DMA_ACTIVE = 3'd1,
        DMA_FLUSH  = 3'd2,
        DMA_DONE   = 3'd3,
        DMA_ERROR  = 3'd4
    } dma_state_t;

    typedef enum logic [1:0] {
        WR_IDLE = 2'd0,
        WR_ADDR = 2'd1,
        WR_RESP = 2'd2
    } wr_state_t;

    // =========================================================================
    // ---- BLOCK 1: axil_ff ----
    // Owns: aw_pend_r, aw_addr_r, w_pend_r, w_data_r, w_strb_r,
    //       bvalid_r, rvalid_r, rdata_r,
    //       enable_r, irq_enable_r, dst_addr_r, length_r,
    //       start_req_r, clear_done_r, clear_error_r.
    // =========================================================================
    logic                  aw_pend_r;
    logic [7:0]            aw_addr_r;
    logic                  w_pend_r;
    logic [31:0]           w_data_r;
    logic [3:0]            w_strb_r;
    logic                  bvalid_r;
    logic                  rvalid_r;
    logic [31:0]           rdata_r;

    logic                  enable_r;
    logic                  irq_enable_r;
    // dst_addr_r is always 64 bits internally so that the DST_HI byte-lane
    // assignments (lines 415-418) are never out-of-range regardless of ADDR_W.
    // When driving AXI address outputs we truncate to ADDR_W bits.
    logic [63:0]           dst_addr_r;
    logic [31:0]           length_r;

    // One-cycle request signals read by dma_ff
    logic                  start_req_r;
    logic                  clear_done_r;
    logic                  clear_error_r;

    // =========================================================================
    // ---- BLOCK 3: dma_ff ----
    // Owns: dma_state, remaining_r, write_addr_r,
    //       pack_data_r, pack_idx_r, pack_strb_r,
    //       word_pend_r, word_data_r, word_strb_r, word_addr_r,
    //       done_sticky_r, error_sticky_r, count_r.
    // =========================================================================
    dma_state_t            dma_state;
    logic [31:0]           remaining_r;
    logic [ADDR_W-1:0]     write_addr_r;

    // Byte packer
    logic [63:0]           pack_data_r;
    logic [2:0]            pack_idx_r;      // next byte slot (0..7)
    logic [7:0]            pack_strb_r;

    // Word handoff to write engine (dma_ff → wr_ff via these registers)
    // word_pend_r: dma_ff sets this when a word is complete.
    //             wr_ff clears it when it latches the word (single cycle).
    logic                  word_pend_r;
    logic [63:0]           word_data_r;
    logic [7:0]            word_strb_r;
    logic [ADDR_W-1:0]     word_addr_r;

    logic                  done_sticky_r;
    logic                  error_sticky_r;
    logic [31:0]           count_r;

    // =========================================================================
    // ---- BLOCK 2: wr_ff ----
    // Owns: wr_state, aw_done_r, w_done_r, wr_data_r, wr_strb_r, wr_addr_r.
    // =========================================================================
    wr_state_t             wr_state;
    logic                  aw_done_r;
    logic                  w_done_r;
    logic [63:0]           wr_data_r;
    logic [7:0]            wr_strb_r;
    logic [ADDR_W-1:0]     wr_addr_r;

    // =========================================================================
    // UART FIFO
    // =========================================================================
    logic [7:0]            fifo_rd_data;
    logic                  fifo_full, fifo_empty;
    logic                  fifo_wr_en, fifo_rd_en;

    dma_fifo #(
        .DATA_W (8),
        .DEPTH  (FIFO_DEPTH)
    ) u_rx_fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (fifo_wr_en),
        .wr_data (uart_rx_data),
        .full    (fifo_full),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rd_data),
        .empty   (fifo_empty),
        .count   ()
    );

    // UART RX → FIFO: accept bytes when DMA is active and FIFO not full.
    assign uart_rx_ready = (dma_state == DMA_ACTIVE) && !fifo_full;
    assign fifo_wr_en    = uart_rx_valid && uart_rx_ready;

    // =========================================================================
    // Combinational signals used across blocks
    // =========================================================================
    wire write_pair = aw_pend_r && w_pend_r;
    wire dma_busy   = (dma_state == DMA_ACTIVE) || (dma_state == DMA_FLUSH);

    // pack_accept: consume one byte from FIFO into the packer.
    // Conditions: DMA is collecting, FIFO has data, no packed word is pending
    // (write engine has accepted the previous word), there are bytes remaining.
    wire pack_accept = (dma_state == DMA_ACTIVE)
                     && !fifo_empty
                     && !word_pend_r
                     && (remaining_r != 32'h0);

    assign fifo_rd_en = pack_accept;

    // The current byte completes the 64-bit word when the packer index hits 7
    // (8th byte) or when this is the last byte of the transfer.
    wire word_complete = pack_accept
                       && ((pack_idx_r == 3'd7) || (remaining_r == 32'd1));

    // beat_done: one-cycle pulse when write engine receives BRESP
    wire beat_done  = (wr_state == WR_RESP) && m_axi_bvalid && m_axi_bready;
    wire beat_error = beat_done && (m_axi_bresp != AXI_RESP_OKAY);

    // Popcount of wr_strb_r: how many bytes were committed in this beat
    logic [3:0] beat_byte_count;
    always_comb begin : gen_popcount
        beat_byte_count = 4'h0;
        for (int b = 0; b < 8; b++)
            beat_byte_count = beat_byte_count + {3'h0, wr_strb_r[b]};
    end

    // =========================================================================
    // AXI4-Lite read-data mux (combinational; used by axil_ff)
    // =========================================================================
    logic [31:0] reg_rdata_comb;
    always_comb begin : gen_rdata
        reg_rdata_comb = 32'h0;
        case (s_axil_araddr[7:0])
            REG_CTRL:   reg_rdata_comb = {29'h0, irq_enable_r, 1'b0, enable_r};
            REG_STATUS: reg_rdata_comb = {29'h0, error_sticky_r, done_sticky_r,
                                          dma_busy};
            REG_DST_LO: reg_rdata_comb = dst_addr_r[31:0];
            REG_DST_HI: begin
                // dst_addr_r is 64-bit; return upper 32 bits.
                // When ADDR_W <= 32, bits [63:32] are always 0 (reset value),
                // so this correctly reads 0x00000000 for a 32-bit configuration.
                reg_rdata_comb = dst_addr_r[63:32];
            end
            REG_LENGTH: reg_rdata_comb = length_r;
            REG_COUNT:  reg_rdata_comb = count_r;
            default:    reg_rdata_comb = 32'h0;
        endcase
    end

    // =========================================================================
    // AXI4-Lite output assignments
    // =========================================================================
    // awready/wready do NOT depend on bvalid — independent channel acceptance.
    assign s_axil_awready = !aw_pend_r;
    assign s_axil_wready  = !w_pend_r;
    assign s_axil_bvalid  = bvalid_r;
    assign s_axil_bresp   = AXI_RESP_OKAY;
    assign s_axil_arready = !rvalid_r;
    assign s_axil_rvalid  = rvalid_r;
    assign s_axil_rdata   = rdata_r;
    assign s_axil_rresp   = AXI_RESP_OKAY;

    // =========================================================================
    // AXI4 write master output assignments
    // =========================================================================
    assign m_axi_awaddr  = wr_addr_r;
    assign m_axi_awlen   = 8'h00;            // single beat
    assign m_axi_awsize  = 3'b011;           // 8 bytes
    assign m_axi_awburst = 2'b01;            // INCR
    assign m_axi_awlock  = 1'b0;
    assign m_axi_awcache = 4'b0011;          // normal non-cacheable bufferable
    assign m_axi_awprot  = 3'b000;           // unprivileged, non-secure, data
    assign m_axi_awqos   = 4'h0;
    assign m_axi_awvalid = (wr_state == WR_ADDR) && !aw_done_r;

    assign m_axi_wdata   = wr_data_r;
    assign m_axi_wstrb   = wr_strb_r;
    assign m_axi_wlast   = 1'b1;             // always last (single-beat burst)
    assign m_axi_wvalid  = (wr_state == WR_ADDR) && !w_done_r;

    assign m_axi_bready  = (wr_state == WR_RESP);

    // =========================================================================
    // Status outputs
    // =========================================================================
    assign dma_active = dma_busy;
    assign dma_done   = done_sticky_r;
    assign dma_error  = error_sticky_r;
    assign irq_o      = irq_enable_r && (done_sticky_r || error_sticky_r);

    // =========================================================================
    // BLOCK 1: axil_ff
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_pend_r     <= 1'b0;
            aw_addr_r     <= '0;
            w_pend_r      <= 1'b0;
            w_data_r      <= '0;
            w_strb_r      <= '0;
            bvalid_r      <= 1'b0;
            rvalid_r      <= 1'b0;
            rdata_r       <= '0;
            enable_r      <= 1'b0;
            irq_enable_r  <= 1'b0;
            dst_addr_r    <= '0;
            length_r      <= '0;
            start_req_r   <= 1'b0;
            clear_done_r  <= 1'b0;
            clear_error_r <= 1'b0;
        end else begin
            // Default: clear one-cycle request signals
            start_req_r   <= 1'b0;
            clear_done_r  <= 1'b0;
            clear_error_r <= 1'b0;

            // ------ AW channel: latch ------
            if (s_axil_awvalid && s_axil_awready) begin
                aw_pend_r <= 1'b1;
                aw_addr_r <= s_axil_awaddr[7:0];
            end

            // ------ W channel: latch ------
            if (s_axil_wvalid && s_axil_wready) begin
                w_pend_r <= 1'b1;
                w_data_r <= s_axil_wdata;
                w_strb_r <= s_axil_wstrb;
            end

            // ------ Execute write when both latched ------
            if (write_pair) begin
                aw_pend_r <= 1'b0;
                w_pend_r  <= 1'b0;
                bvalid_r  <= 1'b1;

                case (aw_addr_r)
                    REG_CTRL: begin
                        if (w_strb_r[0]) begin
                            enable_r     <= w_data_r[0];
                            irq_enable_r <= w_data_r[2];
                        end
                        if (w_strb_r[0] && w_data_r[1])
                            start_req_r <= 1'b1;
                    end
                    REG_STATUS: begin
                        if (w_strb_r[0] && w_data_r[1]) clear_done_r  <= 1'b1;
                        if (w_strb_r[0] && w_data_r[2]) clear_error_r <= 1'b1;
                    end
                    REG_DST_LO: begin
                        if (w_strb_r[0]) dst_addr_r[ 7: 0] <= w_data_r[ 7: 0];
                        if (w_strb_r[1]) dst_addr_r[15: 8] <= w_data_r[15: 8];
                        if (w_strb_r[2]) dst_addr_r[23:16] <= w_data_r[23:16];
                        if (w_strb_r[3]) dst_addr_r[31:24] <= w_data_r[31:24];
                    end
                    REG_DST_HI: begin
                        if (ADDR_W > 32) begin
                            if (w_strb_r[0]) dst_addr_r[39:32] <= w_data_r[ 7: 0];
                            if (w_strb_r[1]) dst_addr_r[47:40] <= w_data_r[15: 8];
                            if (w_strb_r[2]) dst_addr_r[55:48] <= w_data_r[23:16];
                            if (w_strb_r[3]) dst_addr_r[63:56] <= w_data_r[31:24];
                        end
                        // ADDR_W <= 32: silently ignore upper-address writes
                    end
                    REG_LENGTH: begin
                        if (w_strb_r[0]) length_r[ 7: 0] <= w_data_r[ 7: 0];
                        if (w_strb_r[1]) length_r[15: 8] <= w_data_r[15: 8];
                        if (w_strb_r[2]) length_r[23:16] <= w_data_r[23:16];
                        if (w_strb_r[3]) length_r[31:24] <= w_data_r[31:24];
                    end
                    default: ; // REG_COUNT read-only; unknown: silently ignore
                endcase
            end

            // B-channel: deassert bvalid when accepted
            if (bvalid_r && s_axil_bready)
                bvalid_r <= 1'b0;

            // ------ Read path ------
            if (s_axil_arvalid && s_axil_arready) begin
                rdata_r  <= reg_rdata_comb;
                rvalid_r <= 1'b1;
            end
            if (rvalid_r && s_axil_rready)
                rvalid_r <= 1'b0;
        end
    end

    // =========================================================================
    // BLOCK 2: wr_ff — AXI4 write engine
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state  <= WR_IDLE;
            aw_done_r <= 1'b0;
            w_done_r  <= 1'b0;
            wr_data_r <= '0;
            wr_strb_r <= '0;
            wr_addr_r <= '0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    aw_done_r <= 1'b0;
                    w_done_r  <= 1'b0;
                    if (word_pend_r) begin
                        // Latch the packed word from dma_ff
                        wr_data_r <= word_data_r;
                        wr_strb_r <= word_strb_r;
                        wr_addr_r <= word_addr_r;
                        wr_state  <= WR_ADDR;
                    end
                end

                WR_ADDR: begin
                    if (m_axi_awvalid && m_axi_awready) aw_done_r <= 1'b1;
                    if (m_axi_wvalid  && m_axi_wready)  w_done_r  <= 1'b1;
                    // Advance to WR_RESP once both channels have been accepted
                    if ((aw_done_r || (m_axi_awvalid && m_axi_awready)) &&
                        (w_done_r  || (m_axi_wvalid  && m_axi_wready)))
                        wr_state <= WR_RESP;
                end

                WR_RESP: begin
                    if (m_axi_bvalid && m_axi_bready)
                        wr_state <= WR_IDLE;
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // =========================================================================
    // BLOCK 3: dma_ff — DMA FSM, byte packer, count, sticky flags
    //
    // Interaction with wr_ff:
    //   word_pend_r is SET by dma_ff when a 64-bit word is packed.
    //   word_pend_r is CLEARED by dma_ff when wr_ff transitions WR_IDLE→WR_ADDR
    //   (i.e., when wr_state == WR_IDLE && word_pend_r — wr_ff latches it this
    //   cycle, so we clear it the same cycle to avoid a second latch attempt
    //   on the next cycle).
    //   count_r and write_addr_r are updated on beat_done.
    //   error_sticky_r is set on beat_error.
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_state      <= DMA_IDLE;
            remaining_r    <= '0;
            write_addr_r   <= '0;
            pack_data_r    <= '0;
            pack_idx_r     <= '0;
            pack_strb_r    <= '0;
            word_pend_r    <= 1'b0;
            word_data_r    <= '0;
            word_strb_r    <= '0;
            word_addr_r    <= '0;
            done_sticky_r  <= 1'b0;
            error_sticky_r <= 1'b0;
            count_r        <= '0;
        end else begin

            // ------ W1C requests from axil_ff ------
            if (clear_done_r)  done_sticky_r  <= 1'b0;
            if (clear_error_r) error_sticky_r <= 1'b0;

            // ------ Write-beat feedback ------
            // Update count and write address when a beat completes successfully.
            // Set error on a bad BRESP.
            if (beat_done) begin
                if (beat_error) begin
                    error_sticky_r <= 1'b1;
                    // Drive FSM to ERROR on next cycle
                end else begin
                    count_r      <= count_r + {28'h0, beat_byte_count};
                end
            end

            // ------ Byte packer ------
            if (pack_accept) begin
                // Place byte at current pack index (little-endian: idx 0 = WDATA[7:0])
                pack_data_r[pack_idx_r * 8 +: 8] <= fifo_rd_data;
                pack_strb_r[pack_idx_r]           <= 1'b1;

                if (word_complete) begin
                    // Commit the completed/partial word to the word handoff registers.
                    // Inline the final byte into word_data_r because pack_data_r
                    // update is non-blocking (NBA) and not yet visible here.
                    word_data_r                       <= pack_data_r;
                    word_data_r[pack_idx_r * 8 +: 8] <= fifo_rd_data;  // override slot
                    word_strb_r                       <= pack_strb_r;
                    word_strb_r[pack_idx_r]           <= 1'b1;          // override slot
                    word_addr_r                       <= write_addr_r;
                    write_addr_r                      <= write_addr_r + {{(ADDR_W-4){1'b0}}, 4'd8};
                    word_pend_r                       <= 1'b1;
                    // Reset packer for next word
                    pack_data_r <= '0;
                    pack_strb_r <= '0;
                    pack_idx_r  <= '0;
                    // Decrement remaining
                    remaining_r <= remaining_r - 32'd1;
                end else begin
                    pack_idx_r  <= pack_idx_r + 3'd1;
                    remaining_r <= remaining_r - 32'd1;
                end
            end

            // Clear word_pend_r when wr_ff latches the word this cycle
            // (wr_ff is in WR_IDLE and word_pend_r is set → wr_ff moves to WR_ADDR)
            if (word_pend_r && (wr_state == WR_IDLE))
                word_pend_r <= 1'b0;

            // ------ DMA FSM ------
            case (dma_state)

                DMA_IDLE: begin
                    if (start_req_r && enable_r) begin
                        if ((length_r == 32'h0) || (dst_addr_r[2:0] != 3'b0)) begin
                            // Invalid parameters: misaligned or zero length
                            dma_state      <= DMA_ERROR;
                            error_sticky_r <= 1'b1;
                        end else begin
                            dma_state      <= DMA_ACTIVE;
                            remaining_r    <= length_r;
                            write_addr_r   <= dst_addr_r[ADDR_W-1:0];
                            count_r        <= '0;
                            done_sticky_r  <= 1'b0;
                            error_sticky_r <= 1'b0;
                            pack_data_r    <= '0;
                            pack_strb_r    <= '0;
                            pack_idx_r     <= '0;
                            word_pend_r    <= 1'b0;
                        end
                    end
                end

                DMA_ACTIVE: begin
                    // Check for write error (beat_error seen this cycle)
                    if (beat_error) begin
                        dma_state <= DMA_ERROR;
                    // All bytes packed and no word handoff pending
                    end else if ((remaining_r == 32'h0) && !word_pend_r
                                 && (pack_idx_r == 3'h0)) begin
                        dma_state <= DMA_FLUSH;
                    end
                end

                DMA_FLUSH: begin
                    if (beat_error) begin
                        dma_state <= DMA_ERROR;
                    // No word pending and write engine idle: all beats done
                    end else if (!word_pend_r && (wr_state == WR_IDLE)) begin
                        dma_state     <= DMA_DONE;
                        done_sticky_r <= 1'b1;
                    end
                end

                DMA_DONE: begin
                    dma_state <= DMA_IDLE;
                end

                DMA_ERROR: begin
                    // Hold until SW clears error_sticky via STATUS W1C,
                    // or until next valid START (which clears sticky flags).
                    if (!error_sticky_r)
                        dma_state <= DMA_IDLE;
                end

                default: dma_state <= DMA_IDLE;
            endcase
        end
    end

endmodule : dma_uart_to_mem

`default_nettype wire
