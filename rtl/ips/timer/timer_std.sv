// =============================================================================
// File        : timer_std.sv
// Project     : WaveGuard SoC — Honours Project 1602-23-735-045
// Description : Standard 32-bit Timer with AXI4-Lite slave interface,
//               programmable prescaler, auto-reload, and periodic interrupts.
//
// Register Map (offset from base address 0x8000_5000):
//   0x00 : CTRL      [0] EN, [1] AUTO_RELOAD, [2] IE, [3] RESET
//   0x04 : STATUS    [0] INT_PENDING (W1C)
//   0x08 : PRESCALE  [31:0] Clock prescaler divisor
//   0x0C : COUNTER   [31:0] (RO) Current running timer tick value
//   0x10 : LOAD      [31:0] (RW) Reload / compare match value
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module timer_std #(
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

    // Interrupt Output
    output wire                   irq_timer
);

    localparam bit [7:0] ADDR_CTRL     = 8'h00;
    localparam bit [7:0] ADDR_STATUS   = 8'h04;
    localparam bit [7:0] ADDR_PRESCALE = 8'h08;
    localparam bit [7:0] ADDR_COUNTER  = 8'h0C;
    localparam bit [7:0] ADDR_LOAD     = 8'h10;

    reg [31:0] reg_ctrl;
    reg [31:0] reg_status;
    reg [31:0] reg_prescale;
    reg [31:0] reg_counter;
    reg [31:0] reg_load;

    reg [31:0] prescale_cnt;

    wire timer_en    = reg_ctrl[0];
    wire auto_reload = reg_ctrl[1];
    wire timer_ie    = reg_ctrl[2];

    assign irq_timer = reg_status[0] && timer_ie;

    // AXI4-Lite Write Channel
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  awaddr_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            awaddr_latched <= '0;
            awaddr_valid   <= 1'b0;
            reg_ctrl       <= 32'h0;
            reg_status     <= 32'h0;
            reg_prescale   <= 32'h0;
            reg_load       <= 32'hFFFF_FFFF;
        end else begin
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

            if ((s_axi_wready || (s_axi_wvalid && (awaddr_valid || s_axi_awvalid))) &&
                (s_axi_bready || ~s_axi_bvalid)) begin
                reg [7:0] offset;
                offset = awaddr_valid ? awaddr_latched[7:0] : s_axi_awaddr[7:0];

                case (offset)
                    ADDR_CTRL:     reg_ctrl     <= s_axi_wdata;
                    ADDR_STATUS:   reg_status[0]<= reg_status[0] & ~s_axi_wdata[0]; // W1C
                    ADDR_PRESCALE: reg_prescale <= s_axi_wdata;
                    ADDR_LOAD:     reg_load     <= s_axi_wdata;
                    default: ;
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                awaddr_valid <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // Timer match event flag
            if (timer_en && (reg_counter >= reg_load)) begin
                reg_status[0] <= 1'b1;
            end
        end
    end

    // AXI4-Lite Read Channel
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
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[7:0])
                    ADDR_CTRL:     s_axi_rdata <= reg_ctrl;
                    ADDR_STATUS:   s_axi_rdata <= reg_status;
                    ADDR_PRESCALE: s_axi_rdata <= reg_prescale;
                    ADDR_COUNTER:  s_axi_rdata <= reg_counter;
                    ADDR_LOAD:     s_axi_rdata <= reg_load;
                    default:       s_axi_rdata <= 32'h0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready) begin
                    s_axi_rvalid <= 1'b0;
                end
            end
        end
    end

    // Timer Counter Engine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_cnt <= 32'h0;
            reg_counter  <= 32'h0;
        end else if (reg_ctrl[3]) begin // Soft reset
            prescale_cnt <= 32'h0;
            reg_counter  <= 32'h0;
        end else if (timer_en) begin
            if (prescale_cnt >= reg_prescale) begin
                prescale_cnt <= 32'h0;
                if (reg_counter >= reg_load) begin
                    reg_counter <= auto_reload ? 32'h0 : reg_counter;
                end else begin
                    reg_counter <= reg_counter + 1'b1;
                end
            end else begin
                prescale_cnt <= prescale_cnt + 1'b1;
            end
        end
    end

endmodule
`default_nettype wire
