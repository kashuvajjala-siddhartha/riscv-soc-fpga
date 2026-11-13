// =============================================================================
// File        : seven_segment_ctrl.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : Seven-Segment Display Controller with PASS/FAIL/IDLE decoding
//               and AXI4-Lite register access.
//
// Display Encoding:
//   - 00 = IDLE : Displays " - - " (idle dashes) or "----"
//   - 01 = PASS : Displays "PASS" / " P "
//   - 10 = FAIL : Displays "FAIL" / " F "
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module seven_segment_ctrl #(
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

    // Direct hardware status inputs (from CRC or CPU)
    input  wire [1:0]             hw_status_i, // 00=IDLE, 01=PASS, 10=FAIL
    input  wire                   hw_status_en, // 1=use hardware input, 0=use software register

    // Display Hardware Outputs
    output reg  [6:0]             seg_cathodes, // {g, f, e, d, c, b, a} (active low)
    output reg  [3:0]             seg_anodes,   // digit selects (active low)
    output wire                   led_idle,
    output wire                   led_pass,
    output wire                   led_fail
);

    // Register offsets
    localparam bit [7:0] ADDR_STATUS_REG = 8'h00; // [1:0] Status: 00=IDLE, 01=PASS, 10=FAIL, [2]=SW/HW select
    localparam bit [7:0] ADDR_DIGIT_REG  = 8'h04; // Raw 32-bit digit override

    reg [31:0] reg_status;
    reg [31:0] reg_digit_val;

    // Determine current effective status
    wire use_hw = hw_status_en || reg_status[2];
    wire [1:0] eff_status = use_hw ? hw_status_i : reg_status[1:0];

    // Status LED outputs
    assign led_idle = (eff_status == 2'b00);
    assign led_pass = (eff_status == 2'b01);
    assign led_fail = (eff_status == 2'b10);

    // =========================================================================
    // AXI4-Lite Write Channel
    // =========================================================================
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
            reg_status     <= 32'h0; // Default IDLE
            reg_digit_val  <= 32'h0;
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
                reg [7:0] reg_offset;
                reg_offset = awaddr_valid ? awaddr_latched[7:0] : s_axi_awaddr[7:0];

                case (reg_offset)
                    ADDR_STATUS_REG: reg_status    <= s_axi_wdata;
                    ADDR_DIGIT_REG:  reg_digit_val <= s_axi_wdata;
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
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[7:0])
                    ADDR_STATUS_REG: s_axi_rdata <= {29'b0, reg_status[2], eff_status};
                    ADDR_DIGIT_REG:  s_axi_rdata <= reg_digit_val;
                    default:         s_axi_rdata <= 32'h0;
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
    // 7-Segment Multiplexing and Character Decoder
    // =========================================================================
    // Standard 7-seg active-low encoding {g, f, e, d, c, b, a}:
    // 'P': a, b, e, f, g -> 7'b0001100 (0=on, 1=off) -> 7'b0001100
    // 'A': a, b, c, e, f, g -> 7'b0001000
    // 'S': a, c, d, f, g -> 7'b0010010
    // 'F': a, e, f, g -> 7'b0001110
    // 'I': b, c -> 7'b1111001
    // 'L': d, e, f -> 7'b1000111
    // '-': g -> 7'b0111111

    localparam [6:0] SEG_P = 7'b0001100;
    localparam [6:0] SEG_A = 7'b0001000;
    localparam [6:0] SEG_S = 7'b0010010;
    localparam [6:0] SEG_F = 7'b0001110;
    localparam [6:0] SEG_I = 7'b1111001;
    localparam [6:0] SEG_L = 7'b1000111;
    localparam [6:0] SEG_DASH = 7'b0111111;
    localparam [6:0] SEG_OFF  = 7'b1111111;

    reg [1:0] digit_sel;
    reg [15:0] refresh_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 16'h0;
            digit_sel       <= 2'b00;
        end else begin
            refresh_counter <= refresh_counter + 1'b1;
            if (refresh_counter == 16'h0) begin
                digit_sel <= digit_sel + 1'b1;
            end
        end
    end

    always @(*) begin
        case (digit_sel)
            2'b00: seg_anodes = 4'b1110; // Digit 0
            2'b01: seg_anodes = 4'b1101; // Digit 1
            2'b10: seg_anodes = 4'b1011; // Digit 2
            2'b11: seg_anodes = 4'b0111; // Digit 3
        endcase

        case (eff_status)
            2'b01: begin // PASS
                case (digit_sel)
                    2'b00: seg_cathodes = SEG_P;
                    2'b01: seg_cathodes = SEG_A;
                    2'b10: seg_cathodes = SEG_S;
                    2'b11: seg_cathodes = SEG_S;
                endcase
            end
            2'b10: begin // FAIL
                case (digit_sel)
                    2'b00: seg_cathodes = SEG_F;
                    2'b01: seg_cathodes = SEG_A;
                    2'b10: seg_cathodes = SEG_I;
                    2'b11: seg_cathodes = SEG_L;
                endcase
            end
            default: begin // IDLE: "- - -"
                seg_cathodes = SEG_DASH;
            end
        endcase
    end

endmodule
`default_nettype wire
