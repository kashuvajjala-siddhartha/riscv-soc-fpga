// =============================================================================
// File        : enhanced_timer.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : Enhanced Timer with Hardware Performance Monitoring & Watchdog
//               for DMA and CRC-32 operations.
//
// Features:
//   - 32-bit programmable counter with prescaler
//   - Periodic / Compare-match interrupt generation
//   - Hardware execution cycle profiler for DMA and CRC
//   - Watchdog timeout monitor for DMA active and CRC busy durations
//   - Input capture timestamps on dma_done and crc_done pulses
//   - Standard AXI4-Lite slave interface
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module enhanced_timer #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // AXI4-Lite Slave Interface
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [3:0]             s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // Hardware Monitoring Inputs (from DMA & CRC)
    input  wire                   dma_active,
    input  wire                   dma_done,
    input  wire                   crc_busy,
    input  wire                   crc_done,

    // Interrupt Output to CPU
    output wire                   irq_timer
);

    // Register Offsets
    localparam bit [7:0] ADDR_CTRL         = 8'h00;
    localparam bit [7:0] ADDR_STATUS       = 8'h04;
    localparam bit [7:0] ADDR_PRESCALER    = 8'h08;
    localparam bit [7:0] ADDR_COUNTER      = 8'h0C;
    localparam bit [7:0] ADDR_MATCH        = 8'h10;
    localparam bit [7:0] ADDR_DMA_WD_LIMIT = 8'h14;
    localparam bit [7:0] ADDR_CRC_WD_LIMIT = 8'h18;
    localparam bit [7:0] ADDR_DMA_CYCLES   = 8'h1C;
    localparam bit [7:0] ADDR_CRC_CYCLES   = 8'h20;
    localparam bit [7:0] ADDR_DMA_TS       = 8'h24;
    localparam bit [7:0] ADDR_CRC_TS       = 8'h28;

    // Registers
    reg [31:0] reg_ctrl;
    reg [31:0] reg_status;
    reg [31:0] reg_prescaler;
    reg [31:0] reg_counter;
    reg [31:0] reg_match;
    reg [31:0] reg_dma_wd_limit;
    reg [31:0] reg_crc_wd_limit;
    reg [31:0] reg_dma_cycles;
    reg [31:0] reg_crc_cycles;
    reg [31:0] reg_dma_timestamp;
    reg [31:0] reg_crc_timestamp;

    // Prescaler internal counter
    reg [31:0] prescaler_cnt;

    // Edge detectors for done pulses
    reg dma_done_d;
    reg crc_done_d;
    wire dma_done_edge = dma_done && !dma_done_d;
    wire crc_done_edge = crc_done && !crc_done_d;

    // Control bit aliases
    wire timer_enable      = reg_ctrl[0];
    wire auto_reload       = reg_ctrl[1];
    wire ie_match          = reg_ctrl[2];
    wire ie_dma_watchdog   = reg_ctrl[3];
    wire ie_crc_watchdog   = reg_ctrl[4];
    wire ie_capture        = reg_ctrl[5];

    // Status bit aliases
    wire match_int_active  = reg_status[0];
    wire dma_wd_int_active = reg_status[1];
    wire crc_wd_int_active = reg_status[2];
    wire dma_done_capt     = reg_status[3];
    wire crc_done_capt     = reg_status[4];

    // Interrupt output combines enabled sources
    assign irq_timer = (match_int_active  && ie_match)        ||
                       (dma_wd_int_active && ie_dma_watchdog) ||
                       (crc_wd_int_active && ie_crc_watchdog) ||
                       ((dma_done_capt || crc_done_capt) && ie_capture);

    // =========================================================================
    // AXI4-Lite Write Channel
    // =========================================================================
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  awaddr_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            awaddr_latched  <= '0;
            awaddr_valid    <= 1'b0;
            reg_ctrl        <= 32'h0;
            reg_prescaler   <= 32'h0;
            reg_match       <= 32'hFFFF_FFFF;
            reg_dma_wd_limit<= 32'h0;
            reg_crc_wd_limit<= 32'h0;
        end else begin
            // Handshake management
            if (~s_axi_awready && s_axi_awvalid && ~awaddr_valid) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                awaddr_valid   <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            if (~s_axi_wready && s_axi_wvalid && (awaddr_valid || s_axi_awvalid)) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Write execution
            if ((s_axi_wready || (s_axi_wvalid && (awaddr_valid || s_axi_awvalid))) &&
                (s_axi_bready || ~s_axi_bvalid)) begin
                reg [7:0] reg_offset;
                reg_offset = awaddr_valid ? awaddr_latched[7:0] : s_axi_awaddr[7:0];

                case (reg_offset)
                    ADDR_CTRL:         reg_ctrl         <= s_axi_wdata;
                    ADDR_PRESCALER:    reg_prescaler    <= s_axi_wdata;
                    ADDR_MATCH:        reg_match        <= s_axi_wdata;
                    ADDR_DMA_WD_LIMIT: reg_dma_wd_limit <= s_axi_wdata;
                    ADDR_CRC_WD_LIMIT: reg_crc_wd_limit <= s_axi_wdata;
                    default: ;
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                awaddr_valid <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // =========================================================================
    // AXI4-Lite Read Channel
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00; // OKAY

                case (s_axi_araddr[7:0])
                    ADDR_CTRL:         s_axi_rdata <= reg_ctrl;
                    ADDR_STATUS:       s_axi_rdata <= {25'b0, crc_busy, dma_active, reg_status[4:0]};
                    ADDR_PRESCALER:    s_axi_rdata <= reg_prescaler;
                    ADDR_COUNTER:      s_axi_rdata <= reg_counter;
                    ADDR_MATCH:        s_axi_rdata <= reg_match;
                    ADDR_DMA_WD_LIMIT: s_axi_rdata <= reg_dma_wd_limit;
                    ADDR_CRC_WD_LIMIT: s_axi_rdata <= reg_crc_wd_limit;
                    ADDR_DMA_CYCLES:   s_axi_rdata <= reg_dma_cycles;
                    ADDR_CRC_CYCLES:   s_axi_rdata <= reg_crc_cycles;
                    ADDR_DMA_TS:       s_axi_rdata <= reg_dma_timestamp;
                    ADDR_CRC_TS:       s_axi_rdata <= reg_crc_timestamp;
                    default:           s_axi_rdata <= 32'h0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready) begin
                    s_axi_rvalid <= 1'b0;
                end
            end
        end
    end

    // =========================================================================
    // Timer Counter & Prescaler Engine
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler_cnt <= 32'h0;
            reg_counter   <= 32'h0;
        end else if (reg_ctrl[6]) begin // Software reset bit
            prescaler_cnt <= 32'h0;
            reg_counter   <= 32'h0;
        end else if (timer_enable) begin
            if (prescaler_cnt >= reg_prescaler) begin
                prescaler_cnt <= 32'h0;
                if (reg_counter >= reg_match) begin
                    if (auto_reload)
                        reg_counter <= 32'h0;
                end else begin
                    reg_counter <= reg_counter + 1'b1;
                end
            end else begin
                prescaler_cnt <= prescaler_cnt + 1'b1;
            end
        end
    end

    // =========================================================================
    // Hardware Profiling & Watchdog Monitoring for DMA & CRC
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_done_d        <= 1'b0;
            crc_done_d        <= 1'b0;
            reg_status        <= 32'h0;
            reg_dma_cycles    <= 32'h0;
            reg_crc_cycles    <= 32'h0;
            reg_dma_timestamp <= 32'h0;
            reg_crc_timestamp <= 32'h0;
        end else begin
            dma_done_d <= dma_done;
            crc_done_d <= crc_done;

            // Timer compare match event
            if (timer_enable && (reg_counter == reg_match)) begin
                reg_status[0] <= 1'b1;
            end

            // DMA Monitoring & Watchdog
            if (dma_active) begin
                reg_dma_cycles <= reg_dma_cycles + 1'b1;
                if ((reg_dma_wd_limit > 0) && (reg_dma_cycles >= reg_dma_wd_limit)) begin
                    reg_status[1] <= 1'b1; // DMA Watchdog timeout
                end
            end else if (dma_done_edge) begin
                reg_dma_timestamp <= reg_counter;
                reg_status[3]     <= 1'b1; // DMA Done captured
            end

            // CRC Monitoring & Watchdog
            if (crc_busy) begin
                reg_crc_cycles <= reg_crc_cycles + 1'b1;
                if ((reg_crc_wd_limit > 0) && (reg_crc_cycles >= reg_crc_wd_limit)) begin
                    reg_status[2] <= 1'b1; // CRC Watchdog timeout
                end
            end else if (crc_done_edge) begin
                reg_crc_timestamp <= reg_counter;
                reg_status[4]     <= 1'b1; // CRC Done captured
            end

            // Write-1-to-Clear status register via AXI
            if (s_axi_wvalid && (awaddr_valid ? awaddr_latched[7:0] : s_axi_awaddr[7:0]) == ADDR_STATUS) begin
                reg_status[4:0] <= reg_status[4:0] & ~s_axi_wdata[4:0];
                if (s_axi_wdata[5]) reg_dma_cycles <= 32'h0;
                if (s_axi_wdata[6]) reg_crc_cycles <= 32'h0;
            end
        end
    end

endmodule
`default_nettype wire
