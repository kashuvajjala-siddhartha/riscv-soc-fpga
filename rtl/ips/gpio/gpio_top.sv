// =============================================================================
// File        : gpio_top.sv
// Project     : WaveGuard SoC — Honours Project 1602-23-735-045
// Description : 32-bit General Purpose Input/Output (GPIO) Controller
//               with AXI4-Lite slave interface, direction control, and
//               configurable edge/level interrupt generation.
//
// Register Map (offset from base address 0x8000_6000):
//   0x00 : DATA_IN   [31:0] (RO) Current state of external GPIO input pins
//   0x04 : DATA_OUT  [31:0] (RW) Data driven to output pins when DIR=1
//   0x08 : DIR       [31:0] (RW) Pin direction: 1 = Output, 0 = Input
//   0x0C : INT_EN    [31:0] (RW) Per-pin interrupt enable mask
//   0x10 : INT_STAT  [31:0] (W1C) Interrupt pending flags (write-1-to-clear)
//   0x14 : INT_TYPE  [31:0] (RW) Interrupt trigger type: 0 = Rising edge, 1 = High level
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module gpio_top #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned NUM_GPIOS  = 32
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

    // External Physical GPIO Pins
    input  wire [NUM_GPIOS-1:0]   gpio_i,
    output wire [NUM_GPIOS-1:0]   gpio_o,
    output wire [NUM_GPIOS-1:0]   gpio_oe,

    // Interrupt Output to CPU PIC
    output wire                   irq_gpio
);

    // Register Offsets
    localparam bit [7:0] ADDR_DATA_IN  = 8'h00;
    localparam bit [7:0] ADDR_DATA_OUT = 8'h04;
    localparam bit [7:0] ADDR_DIR      = 8'h08;
    localparam bit [7:0] ADDR_INT_EN   = 8'h0C;
    localparam bit [7:0] ADDR_INT_STAT = 8'h10;
    localparam bit [7:0] ADDR_INT_TYPE = 8'h14;

    // Registers
    reg [NUM_GPIOS-1:0] reg_data_out;
    reg [NUM_GPIOS-1:0] reg_dir;
    reg [NUM_GPIOS-1:0] reg_int_en;
    reg [NUM_GPIOS-1:0] reg_int_stat;
    reg [NUM_GPIOS-1:0] reg_int_type;

    // Synchronizers for input pins (2-stage flip-flop)
    reg [NUM_GPIOS-1:0] gpio_sync1;
    reg [NUM_GPIOS-1:0] gpio_sync2;
    reg [NUM_GPIOS-1:0] gpio_sync2_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_sync1   <= '0;
            gpio_sync2   <= '0;
            gpio_sync2_d <= '0;
        end else begin
            gpio_sync1   <= gpio_i;
            gpio_sync2   <= gpio_sync1;
            gpio_sync2_d <= gpio_sync2;
        end
    end

    // Pin connections
    assign gpio_o  = reg_data_out;
    assign gpio_oe = reg_dir;

    // Edge detection
    wire [NUM_GPIOS-1:0] gpio_pos_edge = gpio_sync2 & ~gpio_sync2_d;

    // Interrupt Generation
    assign irq_gpio = |reg_int_stat;

    // AXI4-Lite Write Handshake and Registers
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
            reg_data_out   <= '0;
            reg_dir        <= '0;
            reg_int_en     <= '0;
            reg_int_stat   <= '0;
            reg_int_type   <= '0;
        end else begin
            // Handshake
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

            // Write Execution
            if ((s_axi_wready || (s_axi_wvalid && (awaddr_valid || s_axi_awvalid))) &&
                (s_axi_bready || ~s_axi_bvalid)) begin
                reg [7:0] offset;
                offset = awaddr_valid ? awaddr_latched[7:0] : s_axi_awaddr[7:0];

                case (offset)
                    ADDR_DATA_OUT: reg_data_out <= s_axi_wdata[NUM_GPIOS-1:0];
                    ADDR_DIR:      reg_dir      <= s_axi_wdata[NUM_GPIOS-1:0];
                    ADDR_INT_EN:   reg_int_en   <= s_axi_wdata[NUM_GPIOS-1:0];
                    ADDR_INT_STAT: reg_int_stat <= reg_int_stat & ~s_axi_wdata[NUM_GPIOS-1:0]; // W1C
                    ADDR_INT_TYPE: reg_int_type <= s_axi_wdata[NUM_GPIOS-1:0];
                    default: ;
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                awaddr_valid <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // Interrupt flag setting
            begin : int_detector
                integer i;
                for (i = 0; i < NUM_GPIOS; i = i + 1) begin
                    if (reg_int_en[i]) begin
                        if (reg_int_type[i]) begin
                            // High level
                            if (gpio_sync2[i]) reg_int_stat[i] <= 1'b1;
                        end else begin
                            // Rising edge
                            if (gpio_pos_edge[i]) reg_int_stat[i] <= 1'b1;
                        end
                    end
                end
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
                    ADDR_DATA_IN:  s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, gpio_sync2};
                    ADDR_DATA_OUT: s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, reg_data_out};
                    ADDR_DIR:      s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, reg_dir};
                    ADDR_INT_EN:   s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, reg_int_en};
                    ADDR_INT_STAT: s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, reg_int_stat};
                    ADDR_INT_TYPE: s_axi_rdata <= {{(32-NUM_GPIOS){1'b0}}, reg_int_type};
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

endmodule
`default_nettype wire
