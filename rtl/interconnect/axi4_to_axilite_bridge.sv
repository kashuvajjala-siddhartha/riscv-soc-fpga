// =============================================================================
// File        : axi4_to_axilite_bridge.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : Robust AXI4 (64-bit) to AXI4-Lite (32-bit) Bridge & Crossbar
//               decoding all 7 SoC peripheral blocks:
//                 Port 0: DMA Controller      (0x8000_0000 - 0x8000_0FFF)
//                 Port 1: CRC-32 Engine       (0x8000_1000 - 0x8000_1FFF)
//                 Port 2: Enhanced Timer      (0x8000_2000 - 0x8000_2FFF)
//                 Port 3: 7-Segment Display   (0x8000_3000 - 0x8000_3FFF)
//                 Port 4: UART Controller     (0x8000_4000 - 0x8000_4FFF)
//                 Port 5: Standard Timer      (0x8000_5000 - 0x8000_5FFF)
//                 Port 6: 32-bit GPIO         (0x8000_6000 - 0x8000_6FFF)
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module axi4_to_axilite_bridge #(
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_ID_WIDTH   = 8
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // AXI4 Full Slave Interface (from Interconnect)
    input  wire [AXI_ID_WIDTH-1:0]    s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]                 s_axi_awlen,
    input  wire [2:0]                 s_axi_awsize,
    input  wire [1:0]                 s_axi_awburst,
    input  wire                       s_axi_awlock,
    input  wire [3:0]                 s_axi_awcache,
    input  wire [2:0]                 s_axi_awprot,
    input  wire [3:0]                 s_axi_awqos,
    input  wire                       s_axi_awvalid,
    output wire                       s_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [7:0]                 s_axi_wstrb,
    input  wire                       s_axi_wlast,
    input  wire                       s_axi_wvalid,
    output wire                       s_axi_wready,

    output reg  [AXI_ID_WIDTH-1:0]    s_axi_bid,
    output reg  [1:0]                 s_axi_bresp,
    output reg                        s_axi_bvalid,
    input  wire                       s_axi_bready,

    input  wire [AXI_ID_WIDTH-1:0]    s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]                 s_axi_arlen,
    input  wire [2:0]                 s_axi_arsize,
    input  wire [1:0]                 s_axi_arburst,
    input  wire                       s_axi_arlock,
    input  wire [3:0]                 s_axi_arcache,
    input  wire [2:0]                 s_axi_arprot,
    input  wire [3:0]                 s_axi_arqos,
    input  wire                       s_axi_arvalid,
    output reg                        s_axi_arready,

    output reg  [AXI_ID_WIDTH-1:0]    s_axi_rid,
    output reg  [AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]                 s_axi_rresp,
    output reg                        s_axi_rlast,
    output reg                        s_axi_rvalid,
    input  wire                       s_axi_rready,

    // Port 0: DMA AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m0_axil_awaddr,
    output wire [2:0]                 m0_axil_awprot,
    output wire                       m0_axil_awvalid,
    input  wire                       m0_axil_awready,
    output wire [31:0]                m0_axil_wdata,
    output wire [3:0]                 m0_axil_wstrb,
    output wire                       m0_axil_wvalid,
    input  wire                       m0_axil_wready,
    input  wire [1:0]                 m0_axil_bresp,
    input  wire                       m0_axil_bvalid,
    output wire                       m0_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m0_axil_araddr,
    output wire [2:0]                 m0_axil_arprot,
    output wire                       m0_axil_arvalid,
    input  wire                       m0_axil_arready,
    input  wire [31:0]                m0_axil_rdata,
    input  wire [1:0]                 m0_axil_rresp,
    input  wire                       m0_axil_rvalid,
    output wire                       m0_axil_rready,

    // Port 1: CRC AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m1_axil_awaddr,
    output wire [2:0]                 m1_axil_awprot,
    output wire                       m1_axil_awvalid,
    input  wire                       m1_axil_awready,
    output wire [31:0]                m1_axil_wdata,
    output wire [3:0]                 m1_axil_wstrb,
    output wire                       m1_axil_wvalid,
    input  wire                       m1_axil_wready,
    input  wire [1:0]                 m1_axil_bresp,
    input  wire                       m1_axil_bvalid,
    output wire                       m1_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m1_axil_araddr,
    output wire [2:0]                 m1_axil_arprot,
    output wire                       m1_axil_arvalid,
    input  wire                       m1_axil_arready,
    input  wire [31:0]                m1_axil_rdata,
    input  wire [1:0]                 m1_axil_rresp,
    input  wire                       m1_axil_rvalid,
    output wire                       m1_axil_rready,

    // Port 2: Enhanced Timer AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m2_axil_awaddr,
    output wire [2:0]                 m2_axil_awprot,
    output wire                       m2_axil_awvalid,
    input  wire                       m2_axil_awready,
    output wire [31:0]                m2_axil_wdata,
    output wire [3:0]                 m2_axil_wstrb,
    output wire                       m2_axil_wvalid,
    input  wire                       m2_axil_wready,
    input  wire [1:0]                 m2_axil_bresp,
    input  wire                       m2_axil_bvalid,
    output wire                       m2_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m2_axil_araddr,
    output wire [2:0]                 m2_axil_arprot,
    output wire                       m2_axil_arvalid,
    input  wire                       m2_axil_arready,
    input  wire [31:0]                m2_axil_rdata,
    input  wire [1:0]                 m2_axil_rresp,
    input  wire                       m2_axil_rvalid,
    output wire                       m2_axil_rready,

    // Port 3: 7-Segment Display AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m3_axil_awaddr,
    output wire [2:0]                 m3_axil_awprot,
    output wire                       m3_axil_awvalid,
    input  wire                       m3_axil_awready,
    output wire [31:0]                m3_axil_wdata,
    output wire [3:0]                 m3_axil_wstrb,
    output wire                       m3_axil_wvalid,
    input  wire                       m3_axil_wready,
    input  wire [1:0]                 m3_axil_bresp,
    input  wire                       m3_axil_bvalid,
    output wire                       m3_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m3_axil_araddr,
    output wire [2:0]                 m3_axil_arprot,
    output wire                       m3_axil_arvalid,
    input  wire                       m3_axil_arready,
    input  wire [31:0]                m3_axil_rdata,
    input  wire [1:0]                 m3_axil_rresp,
    input  wire                       m3_axil_rvalid,
    output wire                       m3_axil_rready,

    // Port 4: UART Controller AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m4_axil_awaddr,
    output wire [2:0]                 m4_axil_awprot,
    output wire                       m4_axil_awvalid,
    input  wire                       m4_axil_awready,
    output wire [31:0]                m4_axil_wdata,
    output wire [3:0]                 m4_axil_wstrb,
    output wire                       m4_axil_wvalid,
    input  wire                       m4_axil_wready,
    input  wire [1:0]                 m4_axil_bresp,
    input  wire                       m4_axil_bvalid,
    output wire                       m4_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m4_axil_araddr,
    output wire [2:0]                 m4_axil_arprot,
    output wire                       m4_axil_arvalid,
    input  wire                       m4_axil_arready,
    input  wire [31:0]                m4_axil_rdata,
    input  wire [1:0]                 m4_axil_rresp,
    input  wire                       m4_axil_rvalid,
    output wire                       m4_axil_rready,

    // Port 5: Standard Timer AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m5_axil_awaddr,
    output wire [2:0]                 m5_axil_awprot,
    output wire                       m5_axil_awvalid,
    input  wire                       m5_axil_awready,
    output wire [31:0]                m5_axil_wdata,
    output wire [3:0]                 m5_axil_wstrb,
    output wire                       m5_axil_wvalid,
    input  wire                       m5_axil_wready,
    input  wire [1:0]                 m5_axil_bresp,
    input  wire                       m5_axil_bvalid,
    output wire                       m5_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m5_axil_araddr,
    output wire [2:0]                 m5_axil_arprot,
    output wire                       m5_axil_arvalid,
    input  wire                       m5_axil_arready,
    input  wire [31:0]                m5_axil_rdata,
    input  wire [1:0]                 m5_axil_rresp,
    input  wire                       m5_axil_rvalid,
    output wire                       m5_axil_rready,

    // Port 6: GPIO Controller AXI4-Lite
    output wire [AXI_ADDR_WIDTH-1:0]  m6_axil_awaddr,
    output wire [2:0]                 m6_axil_awprot,
    output wire                       m6_axil_awvalid,
    input  wire                       m6_axil_awready,
    output wire [31:0]                m6_axil_wdata,
    output wire [3:0]                 m6_axil_wstrb,
    output wire                       m6_axil_wvalid,
    input  wire                       m6_axil_wready,
    input  wire [1:0]                 m6_axil_bresp,
    input  wire                       m6_axil_bvalid,
    output wire                       m6_axil_bready,
    output wire [AXI_ADDR_WIDTH-1:0]  m6_axil_araddr,
    output wire [2:0]                 m6_axil_arprot,
    output wire                       m6_axil_arvalid,
    input  wire                       m6_axil_arready,
    input  wire [31:0]                m6_axil_rdata,
    input  wire [1:0]                 m6_axil_rresp,
    input  wire                       m6_axil_rvalid,
    output wire                       m6_axil_rready
);

    // Peripheral Selection Decoder function (Address bits [15:12])
    function automatic [2:0] decode_sel(input [31:0] addr);
        case (addr[15:12])
            4'h0: decode_sel = 3'd0; // DMA
            4'h1: decode_sel = 3'd1; // CRC
            4'h2: decode_sel = 3'd2; // Enhanced Timer
            4'h3: decode_sel = 3'd3; // 7-Segment
            4'h4: decode_sel = 3'd4; // UART CSR
            4'h5: decode_sel = 3'd5; // Standard Timer
            4'h6: decode_sel = 3'd6; // GPIO
            default: decode_sel = 3'd0;
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // Decoupled Write Engine
    // -------------------------------------------------------------------------
    reg                      aw_captured;
    reg                      w_captured;
    reg [AXI_ID_WIDTH-1:0]   w_id;
    reg [AXI_ADDR_WIDTH-1:0] w_addr;
    reg [2:0]                w_prot;
    reg [63:0]               w_data_raw;
    reg [7:0]                w_strb_raw;
    reg [2:0]                w_sel;

    reg                      axil_aw_sent;
    reg                      axil_w_sent;

    assign s_axi_awready = !aw_captured;
    assign s_axi_wready  = !w_captured;

    wire [31:0] wdata_slice = w_addr[2] ? w_data_raw[63:32] : w_data_raw[31:0];
    wire [3:0]  wstrb_slice = w_addr[2] ? w_strb_raw[7:4]   : w_strb_raw[3:0];

    wire axil_issue = aw_captured && w_captured;

    // Macro assignment helper for write channels
    assign m0_axil_awaddr  = w_addr;      assign m0_axil_awprot  = w_prot;
    assign m0_axil_wdata   = wdata_slice; assign m0_axil_wstrb   = wstrb_slice;
    assign m0_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd0);
    assign m0_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd0);
    assign m0_axil_bready  = axil_issue && (w_sel == 3'd0);

    assign m1_axil_awaddr  = w_addr;      assign m1_axil_awprot  = w_prot;
    assign m1_axil_wdata   = wdata_slice; assign m1_axil_wstrb   = wstrb_slice;
    assign m1_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd1);
    assign m1_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd1);
    assign m1_axil_bready  = axil_issue && (w_sel == 3'd1);

    assign m2_axil_awaddr  = w_addr;      assign m2_axil_awprot  = w_prot;
    assign m2_axil_wdata   = wdata_slice; assign m2_axil_wstrb   = wstrb_slice;
    assign m2_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd2);
    assign m2_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd2);
    assign m2_axil_bready  = axil_issue && (w_sel == 3'd2);

    assign m3_axil_awaddr  = w_addr;      assign m3_axil_awprot  = w_prot;
    assign m3_axil_wdata   = wdata_slice; assign m3_axil_wstrb   = wstrb_slice;
    assign m3_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd3);
    assign m3_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd3);
    assign m3_axil_bready  = axil_issue && (w_sel == 3'd3);

    assign m4_axil_awaddr  = w_addr;      assign m4_axil_awprot  = w_prot;
    assign m4_axil_wdata   = wdata_slice; assign m4_axil_wstrb   = wstrb_slice;
    assign m4_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd4);
    assign m4_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd4);
    assign m4_axil_bready  = axil_issue && (w_sel == 3'd4);

    assign m5_axil_awaddr  = w_addr;      assign m5_axil_awprot  = w_prot;
    assign m5_axil_wdata   = wdata_slice; assign m5_axil_wstrb   = wstrb_slice;
    assign m5_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd5);
    assign m5_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd5);
    assign m5_axil_bready  = axil_issue && (w_sel == 3'd5);

    assign m6_axil_awaddr  = w_addr;      assign m6_axil_awprot  = w_prot;
    assign m6_axil_wdata   = wdata_slice; assign m6_axil_wstrb   = wstrb_slice;
    assign m6_axil_awvalid = axil_issue && !axil_aw_sent && (w_sel == 3'd6);
    assign m6_axil_wvalid  = axil_issue && !axil_w_sent  && (w_sel == 3'd6);
    assign m6_axil_bready  = axil_issue && (w_sel == 3'd6);

    wire target_awready = (w_sel == 3'd0) ? m0_axil_awready :
                          (w_sel == 3'd1) ? m1_axil_awready :
                          (w_sel == 3'd2) ? m2_axil_awready :
                          (w_sel == 3'd3) ? m3_axil_awready :
                          (w_sel == 3'd4) ? m4_axil_awready :
                          (w_sel == 3'd5) ? m5_axil_awready : m6_axil_awready;

    wire target_wready  = (w_sel == 3'd0) ? m0_axil_wready :
                          (w_sel == 3'd1) ? m1_axil_wready :
                          (w_sel == 3'd2) ? m2_axil_wready :
                          (w_sel == 3'd3) ? m3_axil_wready :
                          (w_sel == 3'd4) ? m4_axil_wready :
                          (w_sel == 3'd5) ? m5_axil_wready : m6_axil_wready;

    wire target_bvalid  = (w_sel == 3'd0) ? m0_axil_bvalid :
                          (w_sel == 3'd1) ? m1_axil_bvalid :
                          (w_sel == 3'd2) ? m2_axil_bvalid :
                          (w_sel == 3'd3) ? m3_axil_bvalid :
                          (w_sel == 3'd4) ? m4_axil_bvalid :
                          (w_sel == 3'd5) ? m5_axil_bvalid : m6_axil_bvalid;

    wire [1:0] target_bresp = (w_sel == 3'd0) ? m0_axil_bresp :
                              (w_sel == 3'd1) ? m1_axil_bresp :
                              (w_sel == 3'd2) ? m2_axil_bresp :
                              (w_sel == 3'd3) ? m3_axil_bresp :
                              (w_sel == 3'd4) ? m4_axil_bresp :
                              (w_sel == 3'd5) ? m5_axil_bresp : m6_axil_bresp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_captured  <= 1'b0;
            w_captured   <= 1'b0;
            axil_aw_sent <= 1'b0;
            axil_w_sent  <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            s_axi_bid    <= '0;
            w_id         <= '0;
            w_addr       <= '0;
            w_prot       <= '0;
            w_data_raw   <= '0;
            w_strb_raw   <= '0;
            w_sel        <= '0;
        end else begin
            if (!aw_captured && s_axi_awvalid) begin
                aw_captured <= 1'b1;
                w_id        <= s_axi_awid;
                w_addr      <= s_axi_awaddr;
                w_prot      <= s_axi_awprot;
                w_sel       <= decode_sel(s_axi_awaddr);
            end

            if (!w_captured && s_axi_wvalid) begin
                w_captured <= 1'b1;
                w_data_raw <= s_axi_wdata;
                w_strb_raw <= s_axi_wstrb;
            end

            if (axil_issue) begin
                if (target_awready && !axil_aw_sent) axil_aw_sent <= 1'b1;
                if (target_wready  && !axil_w_sent)  axil_w_sent  <= 1'b1;

                if (target_bvalid && (!s_axi_bvalid || s_axi_bready)) begin
                    s_axi_bid    <= w_id;
                    s_axi_bresp  <= target_bresp;
                    s_axi_bvalid <= 1'b1;

                    aw_captured  <= 1'b0;
                    w_captured   <= 1'b0;
                    axil_aw_sent <= 1'b0;
                    axil_w_sent  <= 1'b0;
                end
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read Engine
    // -------------------------------------------------------------------------
    localparam [1:0]
        RS_IDLE = 2'd0,
        RS_ADDR = 2'd1,
        RS_DATA = 2'd2;

    reg [1:0]                r_state;
    reg [AXI_ID_WIDTH-1:0]   r_id;
    reg [AXI_ADDR_WIDTH-1:0] r_addr;
    reg [2:0]                r_prot;
    reg [2:0]                r_sel;

    assign m0_axil_araddr  = r_addr; assign m0_axil_arprot  = r_prot;
    assign m0_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd0);
    assign m0_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd0);

    assign m1_axil_araddr  = r_addr; assign m1_axil_arprot  = r_prot;
    assign m1_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd1);
    assign m1_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd1);

    assign m2_axil_araddr  = r_addr; assign m2_axil_arprot  = r_prot;
    assign m2_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd2);
    assign m2_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd2);

    assign m3_axil_araddr  = r_addr; assign m3_axil_arprot  = r_prot;
    assign m3_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd3);
    assign m3_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd3);

    assign m4_axil_araddr  = r_addr; assign m4_axil_arprot  = r_prot;
    assign m4_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd4);
    assign m4_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd4);

    assign m5_axil_araddr  = r_addr; assign m5_axil_arprot  = r_prot;
    assign m5_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd5);
    assign m5_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd5);

    assign m6_axil_araddr  = r_addr; assign m6_axil_arprot  = r_prot;
    assign m6_axil_arvalid = (r_state == RS_ADDR) && (r_sel == 3'd6);
    assign m6_axil_rready  = (r_state == RS_DATA) && (r_sel == 3'd6);

    wire target_arready = (r_sel == 3'd0) ? m0_axil_arready :
                          (r_sel == 3'd1) ? m1_axil_arready :
                          (r_sel == 3'd2) ? m2_axil_arready :
                          (r_sel == 3'd3) ? m3_axil_arready :
                          (r_sel == 3'd4) ? m4_axil_arready :
                          (r_sel == 3'd5) ? m5_axil_arready : m6_axil_arready;

    wire target_rvalid  = (r_sel == 3'd0) ? m0_axil_rvalid :
                          (r_sel == 3'd1) ? m1_axil_rvalid :
                          (r_sel == 3'd2) ? m2_axil_rvalid :
                          (r_sel == 3'd3) ? m3_axil_rvalid :
                          (r_sel == 3'd4) ? m4_axil_rvalid :
                          (r_sel == 3'd5) ? m5_axil_rvalid : m6_axil_rvalid;

    wire [31:0] target_rdata = (r_sel == 3'd0) ? m0_axil_rdata :
                               (r_sel == 3'd1) ? m1_axil_rdata :
                               (r_sel == 3'd2) ? m2_axil_rdata :
                               (r_sel == 3'd3) ? m3_axil_rdata :
                               (r_sel == 3'd4) ? m4_axil_rdata :
                               (r_sel == 3'd5) ? m5_axil_rdata : m6_axil_rdata;

    wire [1:0] target_rresp  = (r_sel == 3'd0) ? m0_axil_rresp :
                               (r_sel == 3'd1) ? m1_axil_rresp :
                               (r_sel == 3'd2) ? m2_axil_rresp :
                               (r_sel == 3'd3) ? m3_axil_rresp :
                               (r_sel == 3'd4) ? m4_axil_rresp :
                               (r_sel == 3'd5) ? m5_axil_rresp : m6_axil_rresp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_state       <= RS_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= '0;
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            s_axi_rid     <= '0;
            r_id          <= '0;
            r_addr        <= '0;
            r_prot        <= '0;
            r_sel         <= '0;
        end else begin
            case (r_state)
                RS_IDLE: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                    end

                    if (s_axi_arvalid && (~s_axi_rvalid || s_axi_rready)) begin
                        s_axi_arready <= 1'b1;
                        r_id          <= s_axi_arid;
                        r_addr        <= s_axi_araddr;
                        r_prot        <= s_axi_arprot;
                        r_sel         <= decode_sel(s_axi_araddr);
                        r_state       <= RS_ADDR;
                    end
                end

                RS_ADDR: begin
                    s_axi_arready <= 1'b0;
                    if (target_arready) begin
                        r_state <= RS_DATA;
                    end
                end

                RS_DATA: begin
                    if (target_rvalid) begin
                        s_axi_rid    <= r_id;
                        s_axi_rresp  <= target_rresp;
                        s_axi_rlast  <= 1'b1;
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= {target_rdata, target_rdata};
                        r_state      <= RS_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
`default_nettype wire
