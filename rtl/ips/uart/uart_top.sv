// =============================================================================
// File        : uart_top.sv
// Project     : WaveGuard SoC — Honours Project 1602-23-735-045
// Description : Full-Duplex UART Controller with AXI4-Lite CSRs, TX/RX FIFOs,
//               and synchronous streaming link to DMA.
//
// Register Map (offset from base address 0x8000_4000):
//   0x00 : TX_DATA   [7:0] (WO) Write byte to transmit
//   0x04 : RX_DATA   [7:0] (RO) Read byte from receive buffer
//   0x08 : STATUS    [0] RX_VALID, [1] TX_BUSY, [2] TX_READY, [3] LOOPBACK
//   0x0C : CTRL      [0] LOOPBACK_EN, [1] RX_IE, [2] TX_IE, [15:4] BAUD_DIV
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module uart_top #(
    parameter int unsigned ADDR_WIDTH   = 32,
    parameter int unsigned DATA_WIDTH   = 32,
    parameter int unsigned CLKS_PER_BIT = 16
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

    // Physical Serial Pins
    input  wire                   uart_rx,
    output reg                    uart_tx,

    // Direct Streaming Link to DMA
    output wire [7:0]             m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,

    // Interrupt Output
    output wire                   irq_uart
);

    // Register Offsets
    localparam bit [7:0] ADDR_TX_DATA = 8'h00;
    localparam bit [7:0] ADDR_RX_DATA = 8'h04;
    localparam bit [7:0] ADDR_STATUS  = 8'h08;
    localparam bit [7:0] ADDR_CTRL    = 8'h0C;

    reg [31:0] reg_ctrl;

    wire loopback_en = reg_ctrl[0];
    wire rx_ie       = reg_ctrl[1];
    wire tx_ie       = reg_ctrl[2];
    wire [11:0] baud_div = (reg_ctrl[15:4] == 12'h0) ? CLKS_PER_BIT[11:0] : reg_ctrl[15:4];

    // Connect internal RX to external or loopback
    wire rx_line = loopback_en ? uart_tx : uart_rx;

    // Instantiate RX engine
    wire [7:0] rx_byte;
    wire       rx_valid;
    wire       rx_ready;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_rx (
        .clk          (clk),
        .rst_n        (rst_n),
        .uart_rx      (rx_line),
        .m_axis_tdata (rx_byte),
        .m_axis_tvalid(rx_valid),
        .m_axis_tready(rx_ready)
    );

    // Forward stream to DMA and buffer for CSR read
    reg [7:0] rx_buffer;
    reg       rx_has_data;

    assign m_axis_tdata  = rx_byte;
    assign m_axis_tvalid = rx_valid && !loopback_en;
    assign rx_ready      = loopback_en ? 1'b1 : m_axis_tready;

    // TX Engine
    localparam [2:0]
        TX_IDLE  = 3'd0,
        TX_START = 3'd1,
        TX_DATA  = 3'd2,
        TX_STOP  = 3'd3;

    reg [2:0]   tx_state;
    reg [15:0]  tx_clk_cnt;
    reg [2:0]   tx_bit_idx;
    reg [7:0]   tx_shift_reg;
    reg         tx_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_buffer   <= 8'h0;
            rx_has_data <= 1'b0;
        end else begin
            if (rx_valid && (rx_ready || loopback_en)) begin
                rx_buffer   <= rx_byte;
                rx_has_data <= 1'b1;
            end
        end
    end

    // AXI4-Lite Write Channel
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  awaddr_valid;
    reg                  tx_start_req;
    reg [7:0]            tx_byte_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            awaddr_latched <= '0;
            awaddr_valid   <= 1'b0;
            reg_ctrl       <= 32'h0;
            tx_start_req   <= 1'b0;
            tx_byte_req    <= 8'h0;
        end else begin
            tx_start_req <= 1'b0; // Pulse

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
                    ADDR_TX_DATA: begin
                        tx_byte_req  <= s_axi_wdata[7:0];
                        tx_start_req <= 1'b1;
                    end
                    ADDR_CTRL:    reg_ctrl <= s_axi_wdata;
                    default: ;
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                awaddr_valid <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
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
                    ADDR_TX_DATA: s_axi_rdata <= 32'h0;
                    ADDR_RX_DATA: begin
                        s_axi_rdata <= {24'h0, rx_buffer};
                        rx_has_data <= 1'b0; // Auto-clear on read
                    end
                    ADDR_STATUS:  s_axi_rdata <= {28'h0, loopback_en, ~tx_busy, tx_busy, rx_has_data};
                    ADDR_CTRL:    s_axi_rdata <= reg_ctrl;
                    default:      s_axi_rdata <= 32'h0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready) begin
                    s_axi_rvalid <= 1'b0;
                end
            end
        end
    end

    // TX State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state     <= TX_IDLE;
            tx_clk_cnt   <= 16'h0;
            tx_bit_idx   <= 3'h0;
            tx_shift_reg <= 8'h0;
            tx_busy      <= 1'b0;
            uart_tx      <= 1'b1;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    uart_tx    <= 1'b1;
                    tx_clk_cnt <= 16'h0;
                    tx_bit_idx <= 3'h0;
                    if (tx_start_req) begin
                        tx_shift_reg <= tx_byte_req;
                        tx_busy      <= 1'b1;
                        tx_state     <= TX_START;
                    end else begin
                        tx_busy      <= 1'b0;
                    end
                end

                TX_START: begin
                    uart_tx <= 1'b0; // Start bit
                    if (tx_clk_cnt < baud_div - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1'b1;
                    end else begin
                        tx_clk_cnt <= 16'h0;
                        tx_state   <= TX_DATA;
                    end
                end

                TX_DATA: begin
                    uart_tx <= tx_shift_reg[tx_bit_idx];
                    if (tx_clk_cnt < baud_div - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1'b1;
                    end else begin
                        tx_clk_cnt <= 16'h0;
                        if (tx_bit_idx < 7) begin
                            tx_bit_idx <= tx_bit_idx + 1'b1;
                        end else begin
                            tx_bit_idx <= 3'h0;
                            tx_state   <= TX_STOP;
                        end
                    end
                end

                TX_STOP: begin
                    uart_tx <= 1'b1; // Stop bit
                    if (tx_clk_cnt < baud_div - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1'b1;
                    end else begin
                        tx_clk_cnt <= 16'h0;
                        tx_busy    <= 1'b0;
                        tx_state   <= TX_IDLE;
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    // Interrupt: RX data available or TX idle
    assign irq_uart = (rx_has_data && rx_ie) || (~tx_busy && tx_ie);

endmodule
`default_nettype wire
