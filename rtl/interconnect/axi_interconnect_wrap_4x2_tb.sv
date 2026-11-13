// ============================================================================
// Testbench : axi_interconnect_wrap_4x2_tb.sv
//
// Standalone SystemVerilog testbench for axi_interconnect_wrap_4x2.
//
// Tests performed
//  1. Clock and reset
//  2. AXI4 write transactions from every S port (S00–S03)
//  3. AXI4 read  transactions from every S port (S00–S03)
//  4. Address-region routing  M00 @ 0x0000_0000, M01 @ 0x4000_0000
//  5. Response return to the originating S port
//
// Simple in-line AXI4 slave models are provided for M00 and M01.
// No SoC blocks are instantiated.
// ============================================================================

`timescale 1ns / 1ps

module axi_interconnect_wrap_4x2_tb;

// --------------------------------------------------------------------------
// Parameters – must match wrapper defaults
// --------------------------------------------------------------------------
localparam DATA_WIDTH    = 64;
localparam ADDR_WIDTH    = 32;
localparam STRB_WIDTH    = DATA_WIDTH / 8;   // 8
localparam ID_WIDTH      = 8;
localparam AWUSER_WIDTH  = 1;
localparam WUSER_WIDTH   = 1;
localparam BUSER_WIDTH   = 1;
localparam ARUSER_WIDTH  = 1;
localparam RUSER_WIDTH   = 1;

// Address regions matching wrapper defaults
localparam [ADDR_WIDTH-1:0] M00_BASE = 32'h0000_0000;
localparam [ADDR_WIDTH-1:0] M01_BASE = 32'h4000_0000;

// Simulation limits
localparam CLK_PERIOD    = 10;   // ns
localparam TIMEOUT_CYCLES = 2000;

// --------------------------------------------------------------------------
// Clock & reset
// --------------------------------------------------------------------------
logic clk = 0;
logic rst = 1;

always #(CLK_PERIOD/2) clk = ~clk;

// --------------------------------------------------------------------------
// S00 AXI signals
// --------------------------------------------------------------------------
logic [ID_WIDTH-1:0]     s00_awid;   logic [ADDR_WIDTH-1:0]   s00_awaddr;
logic [7:0]              s00_awlen;  logic [2:0]               s00_awsize;
logic [1:0]              s00_awburst;logic                     s00_awlock;
logic [3:0]              s00_awcache;logic [2:0]               s00_awprot;
logic [3:0]              s00_awqos;  logic [AWUSER_WIDTH-1:0]  s00_awuser;
logic                    s00_awvalid;wire                      s00_awready;
logic [DATA_WIDTH-1:0]   s00_wdata;  logic [STRB_WIDTH-1:0]   s00_wstrb;
logic                    s00_wlast;  logic [WUSER_WIDTH-1:0]   s00_wuser;
logic                    s00_wvalid; wire                      s00_wready;
wire  [ID_WIDTH-1:0]     s00_bid;    wire  [1:0]               s00_bresp;
wire  [BUSER_WIDTH-1:0]  s00_buser;  wire                      s00_bvalid;
logic                    s00_bready;
logic [ID_WIDTH-1:0]     s00_arid;   logic [ADDR_WIDTH-1:0]   s00_araddr;
logic [7:0]              s00_arlen;  logic [2:0]               s00_arsize;
logic [1:0]              s00_arburst;logic                     s00_arlock;
logic [3:0]              s00_arcache;logic [2:0]               s00_arprot;
logic [3:0]              s00_arqos;  logic [ARUSER_WIDTH-1:0]  s00_aruser;
logic                    s00_arvalid;wire                      s00_arready;
wire  [ID_WIDTH-1:0]     s00_rid;    wire  [DATA_WIDTH-1:0]   s00_rdata;
wire  [1:0]              s00_rresp;  wire                      s00_rlast;
wire  [RUSER_WIDTH-1:0]  s00_ruser;  wire                      s00_rvalid;
logic                    s00_rready;

// --------------------------------------------------------------------------
// S01 AXI signals
// --------------------------------------------------------------------------
logic [ID_WIDTH-1:0]     s01_awid;   logic [ADDR_WIDTH-1:0]   s01_awaddr;
logic [7:0]              s01_awlen;  logic [2:0]               s01_awsize;
logic [1:0]              s01_awburst;logic                     s01_awlock;
logic [3:0]              s01_awcache;logic [2:0]               s01_awprot;
logic [3:0]              s01_awqos;  logic [AWUSER_WIDTH-1:0]  s01_awuser;
logic                    s01_awvalid;wire                      s01_awready;
logic [DATA_WIDTH-1:0]   s01_wdata;  logic [STRB_WIDTH-1:0]   s01_wstrb;
logic                    s01_wlast;  logic [WUSER_WIDTH-1:0]   s01_wuser;
logic                    s01_wvalid; wire                      s01_wready;
wire  [ID_WIDTH-1:0]     s01_bid;    wire  [1:0]               s01_bresp;
wire  [BUSER_WIDTH-1:0]  s01_buser;  wire                      s01_bvalid;
logic                    s01_bready;
logic [ID_WIDTH-1:0]     s01_arid;   logic [ADDR_WIDTH-1:0]   s01_araddr;
logic [7:0]              s01_arlen;  logic [2:0]               s01_arsize;
logic [1:0]              s01_arburst;logic                     s01_arlock;
logic [3:0]              s01_arcache;logic [2:0]               s01_arprot;
logic [3:0]              s01_arqos;  logic [ARUSER_WIDTH-1:0]  s01_aruser;
logic                    s01_arvalid;wire                      s01_arready;
wire  [ID_WIDTH-1:0]     s01_rid;    wire  [DATA_WIDTH-1:0]   s01_rdata;
wire  [1:0]              s01_rresp;  wire                      s01_rlast;
wire  [RUSER_WIDTH-1:0]  s01_ruser;  wire                      s01_rvalid;
logic                    s01_rready;

// --------------------------------------------------------------------------
// S02 AXI signals
// --------------------------------------------------------------------------
logic [ID_WIDTH-1:0]     s02_awid;   logic [ADDR_WIDTH-1:0]   s02_awaddr;
logic [7:0]              s02_awlen;  logic [2:0]               s02_awsize;
logic [1:0]              s02_awburst;logic                     s02_awlock;
logic [3:0]              s02_awcache;logic [2:0]               s02_awprot;
logic [3:0]              s02_awqos;  logic [AWUSER_WIDTH-1:0]  s02_awuser;
logic                    s02_awvalid;wire                      s02_awready;
logic [DATA_WIDTH-1:0]   s02_wdata;  logic [STRB_WIDTH-1:0]   s02_wstrb;
logic                    s02_wlast;  logic [WUSER_WIDTH-1:0]   s02_wuser;
logic                    s02_wvalid; wire                      s02_wready;
wire  [ID_WIDTH-1:0]     s02_bid;    wire  [1:0]               s02_bresp;
wire  [BUSER_WIDTH-1:0]  s02_buser;  wire                      s02_bvalid;
logic                    s02_bready;
logic [ID_WIDTH-1:0]     s02_arid;   logic [ADDR_WIDTH-1:0]   s02_araddr;
logic [7:0]              s02_arlen;  logic [2:0]               s02_arsize;
logic [1:0]              s02_arburst;logic                     s02_arlock;
logic [3:0]              s02_arcache;logic [2:0]               s02_arprot;
logic [3:0]              s02_arqos;  logic [ARUSER_WIDTH-1:0]  s02_aruser;
logic                    s02_arvalid;wire                      s02_arready;
wire  [ID_WIDTH-1:0]     s02_rid;    wire  [DATA_WIDTH-1:0]   s02_rdata;
wire  [1:0]              s02_rresp;  wire                      s02_rlast;
wire  [RUSER_WIDTH-1:0]  s02_ruser;  wire                      s02_rvalid;
logic                    s02_rready;

// --------------------------------------------------------------------------
// S03 AXI signals
// --------------------------------------------------------------------------
logic [ID_WIDTH-1:0]     s03_awid;   logic [ADDR_WIDTH-1:0]   s03_awaddr;
logic [7:0]              s03_awlen;  logic [2:0]               s03_awsize;
logic [1:0]              s03_awburst;logic                     s03_awlock;
logic [3:0]              s03_awcache;logic [2:0]               s03_awprot;
logic [3:0]              s03_awqos;  logic [AWUSER_WIDTH-1:0]  s03_awuser;
logic                    s03_awvalid;wire                      s03_awready;
logic [DATA_WIDTH-1:0]   s03_wdata;  logic [STRB_WIDTH-1:0]   s03_wstrb;
logic                    s03_wlast;  logic [WUSER_WIDTH-1:0]   s03_wuser;
logic                    s03_wvalid; wire                      s03_wready;
wire  [ID_WIDTH-1:0]     s03_bid;    wire  [1:0]               s03_bresp;
wire  [BUSER_WIDTH-1:0]  s03_buser;  wire                      s03_bvalid;
logic                    s03_bready;
logic [ID_WIDTH-1:0]     s03_arid;   logic [ADDR_WIDTH-1:0]   s03_araddr;
logic [7:0]              s03_arlen;  logic [2:0]               s03_arsize;
logic [1:0]              s03_arburst;logic                     s03_arlock;
logic [3:0]              s03_arcache;logic [2:0]               s03_arprot;
logic [3:0]              s03_arqos;  logic [ARUSER_WIDTH-1:0]  s03_aruser;
logic                    s03_arvalid;wire                      s03_arready;
wire  [ID_WIDTH-1:0]     s03_rid;    wire  [DATA_WIDTH-1:0]   s03_rdata;
wire  [1:0]              s03_rresp;  wire                      s03_rlast;
wire  [RUSER_WIDTH-1:0]  s03_ruser;  wire                      s03_rvalid;
logic                    s03_rready;

// --------------------------------------------------------------------------
// M00 AXI signals (driven by slave model)
// --------------------------------------------------------------------------
wire  [ID_WIDTH-1:0]     m00_awid;   wire  [ADDR_WIDTH-1:0]   m00_awaddr;
wire  [7:0]              m00_awlen;  wire  [2:0]               m00_awsize;
wire  [1:0]              m00_awburst;wire                      m00_awlock;
wire  [3:0]              m00_awcache;wire  [2:0]               m00_awprot;
wire  [3:0]              m00_awqos;  wire  [3:0]               m00_awregion;
wire  [AWUSER_WIDTH-1:0] m00_awuser; wire                      m00_awvalid;
logic                    m00_awready;
wire  [DATA_WIDTH-1:0]   m00_wdata;  wire  [STRB_WIDTH-1:0]   m00_wstrb;
wire                     m00_wlast;  wire  [WUSER_WIDTH-1:0]  m00_wuser;
wire                     m00_wvalid; logic                     m00_wready;
logic [ID_WIDTH-1:0]     m00_bid;    logic [1:0]               m00_bresp;
logic [BUSER_WIDTH-1:0]  m00_buser;  logic                     m00_bvalid;
wire                     m00_bready;
wire  [ID_WIDTH-1:0]     m00_arid;   wire  [ADDR_WIDTH-1:0]   m00_araddr;
wire  [7:0]              m00_arlen;  wire  [2:0]               m00_arsize;
wire  [1:0]              m00_arburst;wire                      m00_arlock;
wire  [3:0]              m00_arcache;wire  [2:0]               m00_arprot;
wire  [3:0]              m00_arqos;  wire  [3:0]               m00_arregion;
wire  [ARUSER_WIDTH-1:0] m00_aruser; wire                      m00_arvalid;
logic                    m00_arready;
logic [ID_WIDTH-1:0]     m00_rid;    logic [DATA_WIDTH-1:0]   m00_rdata;
logic [1:0]              m00_rresp;  logic                     m00_rlast;
logic [RUSER_WIDTH-1:0]  m00_ruser;  logic                     m00_rvalid;
wire                     m00_rready;

// --------------------------------------------------------------------------
// M01 AXI signals (driven by slave model)
// --------------------------------------------------------------------------
wire  [ID_WIDTH-1:0]     m01_awid;   wire  [ADDR_WIDTH-1:0]   m01_awaddr;
wire  [7:0]              m01_awlen;  wire  [2:0]               m01_awsize;
wire  [1:0]              m01_awburst;wire                      m01_awlock;
wire  [3:0]              m01_awcache;wire  [2:0]               m01_awprot;
wire  [3:0]              m01_awqos;  wire  [3:0]               m01_awregion;
wire  [AWUSER_WIDTH-1:0] m01_awuser; wire                      m01_awvalid;
logic                    m01_awready;
wire  [DATA_WIDTH-1:0]   m01_wdata;  wire  [STRB_WIDTH-1:0]   m01_wstrb;
wire                     m01_wlast;  wire  [WUSER_WIDTH-1:0]  m01_wuser;
wire                     m01_wvalid; logic                     m01_wready;
logic [ID_WIDTH-1:0]     m01_bid;    logic [1:0]               m01_bresp;
logic [BUSER_WIDTH-1:0]  m01_buser;  logic                     m01_bvalid;
wire                     m01_bready;
wire  [ID_WIDTH-1:0]     m01_arid;   wire  [ADDR_WIDTH-1:0]   m01_araddr;
wire  [7:0]              m01_arlen;  wire  [2:0]               m01_arsize;
wire  [1:0]              m01_arburst;wire                      m01_arlock;
wire  [3:0]              m01_arcache;wire  [2:0]               m01_arprot;
wire  [3:0]              m01_arqos;  wire  [3:0]               m01_arregion;
wire  [ARUSER_WIDTH-1:0] m01_aruser; wire                      m01_arvalid;
logic                    m01_arready;
logic [ID_WIDTH-1:0]     m01_rid;    logic [DATA_WIDTH-1:0]   m01_rdata;
logic [1:0]              m01_rresp;  logic                     m01_rlast;
logic [RUSER_WIDTH-1:0]  m01_ruser;  logic                     m01_rvalid;
wire                     m01_rready;

// --------------------------------------------------------------------------
// DUT instantiation
// --------------------------------------------------------------------------
axi_interconnect_wrap_4x2 #(
    .DATA_WIDTH    (DATA_WIDTH),
    .ADDR_WIDTH    (ADDR_WIDTH),
    .STRB_WIDTH    (STRB_WIDTH),
    .ID_WIDTH      (ID_WIDTH),
    .AWUSER_ENABLE (0),
    .AWUSER_WIDTH  (AWUSER_WIDTH),
    .WUSER_ENABLE  (0),
    .WUSER_WIDTH   (WUSER_WIDTH),
    .BUSER_ENABLE  (0),
    .BUSER_WIDTH   (BUSER_WIDTH),
    .ARUSER_ENABLE (0),
    .ARUSER_WIDTH  (ARUSER_WIDTH),
    .RUSER_ENABLE  (0),
    .RUSER_WIDTH   (RUSER_WIDTH),
    .FORWARD_ID    (0),
    .M_REGIONS     (1),
    .M00_BASE_ADDR (32'h0000_0000),
    .M00_ADDR_WIDTH({1{32'd30}}),   // covers 0x0000_0000 – 0x3FFF_FFFF
    .M00_CONNECT_READ (4'b1111),
    .M00_CONNECT_WRITE(4'b1111),
    .M00_SECURE    (1'b0),
    .M01_BASE_ADDR (32'h4000_0000),
    .M01_ADDR_WIDTH({1{32'd30}}),   // covers 0x4000_0000 – 0x7FFF_FFFF
    .M01_CONNECT_READ (4'b1111),
    .M01_CONNECT_WRITE(4'b1111),
    .M01_SECURE    (1'b0)
) dut (
    .clk (clk),
    .rst (rst),

    // S00
    .s00_axi_awid    (s00_awid),   .s00_axi_awaddr  (s00_awaddr),
    .s00_axi_awlen   (s00_awlen),  .s00_axi_awsize  (s00_awsize),
    .s00_axi_awburst (s00_awburst),.s00_axi_awlock  (s00_awlock),
    .s00_axi_awcache (s00_awcache),.s00_axi_awprot  (s00_awprot),
    .s00_axi_awqos   (s00_awqos),  .s00_axi_awuser  (s00_awuser),
    .s00_axi_awvalid (s00_awvalid),.s00_axi_awready (s00_awready),
    .s00_axi_wdata   (s00_wdata),  .s00_axi_wstrb   (s00_wstrb),
    .s00_axi_wlast   (s00_wlast),  .s00_axi_wuser   (s00_wuser),
    .s00_axi_wvalid  (s00_wvalid), .s00_axi_wready  (s00_wready),
    .s00_axi_bid     (s00_bid),    .s00_axi_bresp   (s00_bresp),
    .s00_axi_buser   (s00_buser),  .s00_axi_bvalid  (s00_bvalid),
    .s00_axi_bready  (s00_bready),
    .s00_axi_arid    (s00_arid),   .s00_axi_araddr  (s00_araddr),
    .s00_axi_arlen   (s00_arlen),  .s00_axi_arsize  (s00_arsize),
    .s00_axi_arburst (s00_arburst),.s00_axi_arlock  (s00_arlock),
    .s00_axi_arcache (s00_arcache),.s00_axi_arprot  (s00_arprot),
    .s00_axi_arqos   (s00_arqos),  .s00_axi_aruser  (s00_aruser),
    .s00_axi_arvalid (s00_arvalid),.s00_axi_arready (s00_arready),
    .s00_axi_rid     (s00_rid),    .s00_axi_rdata   (s00_rdata),
    .s00_axi_rresp   (s00_rresp),  .s00_axi_rlast   (s00_rlast),
    .s00_axi_ruser   (s00_ruser),  .s00_axi_rvalid  (s00_rvalid),
    .s00_axi_rready  (s00_rready),

    // S01
    .s01_axi_awid    (s01_awid),   .s01_axi_awaddr  (s01_awaddr),
    .s01_axi_awlen   (s01_awlen),  .s01_axi_awsize  (s01_awsize),
    .s01_axi_awburst (s01_awburst),.s01_axi_awlock  (s01_awlock),
    .s01_axi_awcache (s01_awcache),.s01_axi_awprot  (s01_awprot),
    .s01_axi_awqos   (s01_awqos),  .s01_axi_awuser  (s01_awuser),
    .s01_axi_awvalid (s01_awvalid),.s01_axi_awready (s01_awready),
    .s01_axi_wdata   (s01_wdata),  .s01_axi_wstrb   (s01_wstrb),
    .s01_axi_wlast   (s01_wlast),  .s01_axi_wuser   (s01_wuser),
    .s01_axi_wvalid  (s01_wvalid), .s01_axi_wready  (s01_wready),
    .s01_axi_bid     (s01_bid),    .s01_axi_bresp   (s01_bresp),
    .s01_axi_buser   (s01_buser),  .s01_axi_bvalid  (s01_bvalid),
    .s01_axi_bready  (s01_bready),
    .s01_axi_arid    (s01_arid),   .s01_axi_araddr  (s01_araddr),
    .s01_axi_arlen   (s01_arlen),  .s01_axi_arsize  (s01_arsize),
    .s01_axi_arburst (s01_arburst),.s01_axi_arlock  (s01_arlock),
    .s01_axi_arcache (s01_arcache),.s01_axi_arprot  (s01_arprot),
    .s01_axi_arqos   (s01_arqos),  .s01_axi_aruser  (s01_aruser),
    .s01_axi_arvalid (s01_arvalid),.s01_axi_arready (s01_arready),
    .s01_axi_rid     (s01_rid),    .s01_axi_rdata   (s01_rdata),
    .s01_axi_rresp   (s01_rresp),  .s01_axi_rlast   (s01_rlast),
    .s01_axi_ruser   (s01_ruser),  .s01_axi_rvalid  (s01_rvalid),
    .s01_axi_rready  (s01_rready),

    // S02
    .s02_axi_awid    (s02_awid),   .s02_axi_awaddr  (s02_awaddr),
    .s02_axi_awlen   (s02_awlen),  .s02_axi_awsize  (s02_awsize),
    .s02_axi_awburst (s02_awburst),.s02_axi_awlock  (s02_awlock),
    .s02_axi_awcache (s02_awcache),.s02_axi_awprot  (s02_awprot),
    .s02_axi_awqos   (s02_awqos),  .s02_axi_awuser  (s02_awuser),
    .s02_axi_awvalid (s02_awvalid),.s02_axi_awready (s02_awready),
    .s02_axi_wdata   (s02_wdata),  .s02_axi_wstrb   (s02_wstrb),
    .s02_axi_wlast   (s02_wlast),  .s02_axi_wuser   (s02_wuser),
    .s02_axi_wvalid  (s02_wvalid), .s02_axi_wready  (s02_wready),
    .s02_axi_bid     (s02_bid),    .s02_axi_bresp   (s02_bresp),
    .s02_axi_buser   (s02_buser),  .s02_axi_bvalid  (s02_bvalid),
    .s02_axi_bready  (s02_bready),
    .s02_axi_arid    (s02_arid),   .s02_axi_araddr  (s02_araddr),
    .s02_axi_arlen   (s02_arlen),  .s02_axi_arsize  (s02_arsize),
    .s02_axi_arburst (s02_arburst),.s02_axi_arlock  (s02_arlock),
    .s02_axi_arcache (s02_arcache),.s02_axi_arprot  (s02_arprot),
    .s02_axi_arqos   (s02_arqos),  .s02_axi_aruser  (s02_aruser),
    .s02_axi_arvalid (s02_arvalid),.s02_axi_arready (s02_arready),
    .s02_axi_rid     (s02_rid),    .s02_axi_rdata   (s02_rdata),
    .s02_axi_rresp   (s02_rresp),  .s02_axi_rlast   (s02_rlast),
    .s02_axi_ruser   (s02_ruser),  .s02_axi_rvalid  (s02_rvalid),
    .s02_axi_rready  (s02_rready),

    // S03
    .s03_axi_awid    (s03_awid),   .s03_axi_awaddr  (s03_awaddr),
    .s03_axi_awlen   (s03_awlen),  .s03_axi_awsize  (s03_awsize),
    .s03_axi_awburst (s03_awburst),.s03_axi_awlock  (s03_awlock),
    .s03_axi_awcache (s03_awcache),.s03_axi_awprot  (s03_awprot),
    .s03_axi_awqos   (s03_awqos),  .s03_axi_awuser  (s03_awuser),
    .s03_axi_awvalid (s03_awvalid),.s03_axi_awready (s03_awready),
    .s03_axi_wdata   (s03_wdata),  .s03_axi_wstrb   (s03_wstrb),
    .s03_axi_wlast   (s03_wlast),  .s03_axi_wuser   (s03_wuser),
    .s03_axi_wvalid  (s03_wvalid), .s03_axi_wready  (s03_wready),
    .s03_axi_bid     (s03_bid),    .s03_axi_bresp   (s03_bresp),
    .s03_axi_buser   (s03_buser),  .s03_axi_bvalid  (s03_bvalid),
    .s03_axi_bready  (s03_bready),
    .s03_axi_arid    (s03_arid),   .s03_axi_araddr  (s03_araddr),
    .s03_axi_arlen   (s03_arlen),  .s03_axi_arsize  (s03_arsize),
    .s03_axi_arburst (s03_arburst),.s03_axi_arlock  (s03_arlock),
    .s03_axi_arcache (s03_arcache),.s03_axi_arprot  (s03_arprot),
    .s03_axi_arqos   (s03_arqos),  .s03_axi_aruser  (s03_aruser),
    .s03_axi_arvalid (s03_arvalid),.s03_axi_arready (s03_arready),
    .s03_axi_rid     (s03_rid),    .s03_axi_rdata   (s03_rdata),
    .s03_axi_rresp   (s03_rresp),  .s03_axi_rlast   (s03_rlast),
    .s03_axi_ruser   (s03_ruser),  .s03_axi_rvalid  (s03_rvalid),
    .s03_axi_rready  (s03_rready),

    // M00
    .m00_axi_awid    (m00_awid),   .m00_axi_awaddr  (m00_awaddr),
    .m00_axi_awlen   (m00_awlen),  .m00_axi_awsize  (m00_awsize),
    .m00_axi_awburst (m00_awburst),.m00_axi_awlock  (m00_awlock),
    .m00_axi_awcache (m00_awcache),.m00_axi_awprot  (m00_awprot),
    .m00_axi_awqos   (m00_awqos),  .m00_axi_awregion(m00_awregion),
    .m00_axi_awuser  (m00_awuser), .m00_axi_awvalid (m00_awvalid),
    .m00_axi_awready (m00_awready),
    .m00_axi_wdata   (m00_wdata),  .m00_axi_wstrb   (m00_wstrb),
    .m00_axi_wlast   (m00_wlast),  .m00_axi_wuser   (m00_wuser),
    .m00_axi_wvalid  (m00_wvalid), .m00_axi_wready  (m00_wready),
    .m00_axi_bid     (m00_bid),    .m00_axi_bresp   (m00_bresp),
    .m00_axi_buser   (m00_buser),  .m00_axi_bvalid  (m00_bvalid),
    .m00_axi_bready  (m00_bready),
    .m00_axi_arid    (m00_arid),   .m00_axi_araddr  (m00_araddr),
    .m00_axi_arlen   (m00_arlen),  .m00_axi_arsize  (m00_arsize),
    .m00_axi_arburst (m00_arburst),.m00_axi_arlock  (m00_arlock),
    .m00_axi_arcache (m00_arcache),.m00_axi_arprot  (m00_arprot),
    .m00_axi_arqos   (m00_arqos),  .m00_axi_arregion(m00_arregion),
    .m00_axi_aruser  (m00_aruser), .m00_axi_arvalid (m00_arvalid),
    .m00_axi_arready (m00_arready),
    .m00_axi_rid     (m00_rid),    .m00_axi_rdata   (m00_rdata),
    .m00_axi_rresp   (m00_rresp),  .m00_axi_rlast   (m00_rlast),
    .m00_axi_ruser   (m00_ruser),  .m00_axi_rvalid  (m00_rvalid),
    .m00_axi_rready  (m00_rready),

    // M01
    .m01_axi_awid    (m01_awid),   .m01_axi_awaddr  (m01_awaddr),
    .m01_axi_awlen   (m01_awlen),  .m01_axi_awsize  (m01_awsize),
    .m01_axi_awburst (m01_awburst),.m01_axi_awlock  (m01_awlock),
    .m01_axi_awcache (m01_awcache),.m01_axi_awprot  (m01_awprot),
    .m01_axi_awqos   (m01_awqos),  .m01_axi_awregion(m01_awregion),
    .m01_axi_awuser  (m01_awuser), .m01_axi_awvalid (m01_awvalid),
    .m01_axi_awready (m01_awready),
    .m01_axi_wdata   (m01_wdata),  .m01_axi_wstrb   (m01_wstrb),
    .m01_axi_wlast   (m01_wlast),  .m01_axi_wuser   (m01_wuser),
    .m01_axi_wvalid  (m01_wvalid), .m01_axi_wready  (m01_wready),
    .m01_axi_bid     (m01_bid),    .m01_axi_bresp   (m01_bresp),
    .m01_axi_buser   (m01_buser),  .m01_axi_bvalid  (m01_bvalid),
    .m01_axi_bready  (m01_bready),
    .m01_axi_arid    (m01_arid),   .m01_axi_araddr  (m01_araddr),
    .m01_axi_arlen   (m01_arlen),  .m01_axi_arsize  (m01_arsize),
    .m01_axi_arburst (m01_arburst),.m01_axi_arlock  (m01_arlock),
    .m01_axi_arcache (m01_arcache),.m01_axi_arprot  (m01_arprot),
    .m01_axi_arqos   (m01_arqos),  .m01_axi_arregion(m01_arregion),
    .m01_axi_aruser  (m01_aruser), .m01_axi_arvalid (m01_arvalid),
    .m01_axi_arready (m01_arready),
    .m01_axi_rid     (m01_rid),    .m01_axi_rdata   (m01_rdata),
    .m01_axi_rresp   (m01_rresp),  .m01_axi_rlast   (m01_rlast),
    .m01_axi_ruser   (m01_ruser),  .m01_axi_rvalid  (m01_rvalid),
    .m01_axi_rready  (m01_rready)
);

// --------------------------------------------------------------------------
// Waveform dump
// --------------------------------------------------------------------------
  initial begin
    $fsdbDumpfile("axi_interconnect_wrap_4x2_tb.fsdb");
    $fsdbDumpvars(0, axi_interconnect_wrap_4x2_tb);

end
// --------------------------------------------------------------------------
// Pass/fail counters
// --------------------------------------------------------------------------
int pass_cnt = 0;
int fail_cnt = 0;

task automatic pass_check(input string test_name);
    $display("[PASS] %s  (time=%0t)", test_name, $time);
    pass_cnt++;
endtask

task automatic fail_check(input string test_name, input string reason);
    $display("[FAIL] %s  reason: %s  (time=%0t)", test_name, reason, $time);
    fail_cnt++;
endtask

// --------------------------------------------------------------------------
// Timeout watchdog
// --------------------------------------------------------------------------
int cycle_cnt = 0;
always @(posedge clk) cycle_cnt++;

// --------------------------------------------------------------------------
// Helper: idle all S-port outputs to 0
// --------------------------------------------------------------------------
task automatic idle_s00();
    s00_awvalid = 0; s00_awid = 0; s00_awaddr = 0;
    s00_awlen = 0; s00_awsize = 3'b011; s00_awburst = 2'b01;
    s00_awlock = 0; s00_awcache = 0; s00_awprot = 0;
    s00_awqos = 0; s00_awuser = 0;
    s00_wvalid = 0; s00_wdata = 0; s00_wstrb = 8'hFF;
    s00_wlast = 0; s00_wuser = 0;
    s00_bready = 1;
    s00_arvalid = 0; s00_arid = 0; s00_araddr = 0;
    s00_arlen = 0; s00_arsize = 3'b011; s00_arburst = 2'b01;
    s00_arlock = 0; s00_arcache = 0; s00_arprot = 0;
    s00_arqos = 0; s00_aruser = 0;
    s00_rready = 1;
endtask

task automatic idle_s01();
    s01_awvalid = 0; s01_awid = 0; s01_awaddr = 0;
    s01_awlen = 0; s01_awsize = 3'b011; s01_awburst = 2'b01;
    s01_awlock = 0; s01_awcache = 0; s01_awprot = 0;
    s01_awqos = 0; s01_awuser = 0;
    s01_wvalid = 0; s01_wdata = 0; s01_wstrb = 8'hFF;
    s01_wlast = 0; s01_wuser = 0;
    s01_bready = 1;
    s01_arvalid = 0; s01_arid = 0; s01_araddr = 0;
    s01_arlen = 0; s01_arsize = 3'b011; s01_arburst = 2'b01;
    s01_arlock = 0; s01_arcache = 0; s01_arprot = 0;
    s01_arqos = 0; s01_aruser = 0;
    s01_rready = 1;
endtask

task automatic idle_s02();
    s02_awvalid = 0; s02_awid = 0; s02_awaddr = 0;
    s02_awlen = 0; s02_awsize = 3'b011; s02_awburst = 2'b01;
    s02_awlock = 0; s02_awcache = 0; s02_awprot = 0;
    s02_awqos = 0; s02_awuser = 0;
    s02_wvalid = 0; s02_wdata = 0; s02_wstrb = 8'hFF;
    s02_wlast = 0; s02_wuser = 0;
    s02_bready = 1;
    s02_arvalid = 0; s02_arid = 0; s02_araddr = 0;
    s02_arlen = 0; s02_arsize = 3'b011; s02_arburst = 2'b01;
    s02_arlock = 0; s02_arcache = 0; s02_arprot = 0;
    s02_arqos = 0; s02_aruser = 0;
    s02_rready = 1;
endtask

task automatic idle_s03();
    s03_awvalid = 0; s03_awid = 0; s03_awaddr = 0;
    s03_awlen = 0; s03_awsize = 3'b011; s03_awburst = 2'b01;
    s03_awlock = 0; s03_awcache = 0; s03_awprot = 0;
    s03_awqos = 0; s03_awuser = 0;
    s03_wvalid = 0; s03_wdata = 0; s03_wstrb = 8'hFF;
    s03_wlast = 0; s03_wuser = 0;
    s03_bready = 1;
    s03_arvalid = 0; s03_arid = 0; s03_araddr = 0;
    s03_arlen = 0; s03_arsize = 3'b011; s03_arburst = 2'b01;
    s03_arlock = 0; s03_arcache = 0; s03_arprot = 0;
    s03_arqos = 0; s03_aruser = 0;
    s03_rready = 1;
endtask

// --------------------------------------------------------------------------
// AXI4 Slave Model – M00
//   - Accepts write address and data, replies OKAY bresp
//   - Accepts read address, returns data = addr[31:0] | 'hA5A5 pattern
// --------------------------------------------------------------------------
// Write FSM state
typedef enum logic [1:0] {S_WR_IDLE, S_WR_ADDR, S_WR_DATA, S_WR_RESP} wr_state_t;
typedef enum logic [1:0] {S_RD_IDLE, S_RD_ADDR, S_RD_DATA}             rd_state_t;

wr_state_t m00_wr_state;
rd_state_t m00_rd_state;
logic [ID_WIDTH-1:0]   m00_saved_awid;
logic [7:0]            m00_beats_rem;
logic [ID_WIDTH-1:0]   m00_saved_arid;
logic [7:0]            m00_rd_beats;
logic [ADDR_WIDTH-1:0] m00_rd_base_addr;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        m00_awready    <= 1'b0;
        m00_wready     <= 1'b0;
        m00_bvalid     <= 1'b0;
        m00_bid        <= '0;
        m00_bresp      <= 2'b00;
        m00_buser      <= '0;
        m00_arready    <= 1'b0;
        m00_rvalid     <= 1'b0;
        m00_rid        <= '0;
        m00_rdata      <= '0;
        m00_rresp      <= 2'b00;
        m00_rlast      <= 1'b0;
        m00_ruser      <= '0;
        m00_wr_state   <= S_WR_IDLE;
        m00_rd_state   <= S_RD_IDLE;
    end else begin
        // ---- write path ----
        case (m00_wr_state)
            S_WR_IDLE: begin
                m00_awready <= 1'b1;
                m00_wr_state <= S_WR_ADDR;
            end
            S_WR_ADDR: begin
                if (m00_awvalid && m00_awready) begin
                    m00_saved_awid <= m00_awid;
                    m00_beats_rem  <= m00_awlen;
                    m00_awready    <= 1'b0;
                    m00_wready     <= 1'b1;
                    m00_wr_state   <= S_WR_DATA;
                end
            end
            S_WR_DATA: begin
                if (m00_wvalid && m00_wready) begin
                    if (m00_wlast || m00_beats_rem == 0) begin
                        m00_wready   <= 1'b0;
                        m00_bvalid   <= 1'b1;
                        m00_bid      <= m00_saved_awid;
                        m00_bresp    <= 2'b00; // OKAY
                        m00_wr_state <= S_WR_RESP;
                    end else begin
                        m00_beats_rem <= m00_beats_rem - 1;
                    end
                end
            end
            S_WR_RESP: begin
                if (m00_bready && m00_bvalid) begin
                    m00_bvalid   <= 1'b0;
                    m00_awready  <= 1'b1;
                    m00_wr_state <= S_WR_ADDR;
                end
            end
            default: m00_wr_state <= S_WR_IDLE;
        endcase

        // ---- read path ----
        case (m00_rd_state)
            S_RD_IDLE: begin
                m00_arready  <= 1'b1;
                m00_rd_state <= S_RD_ADDR;
            end
            S_RD_ADDR: begin
                if (m00_arvalid && m00_arready) begin
                    m00_saved_arid   <= m00_arid;
                    m00_rd_beats     <= m00_arlen;
                    m00_rd_base_addr <= m00_araddr;
                    m00_arready      <= 1'b0;
                    m00_rvalid       <= 1'b1;
                    m00_rid          <= m00_arid;
                    m00_rdata        <= {m00_araddr[31:0], 32'hA5A5_0000} >> 0;
                    m00_rdata        <= {32'hA5A5_0000 | m00_araddr[31:0]};
                    m00_rresp        <= 2'b00;
                    m00_rlast        <= (m00_arlen == 8'd0);
                    m00_rd_state     <= S_RD_DATA;
                end
            end
            S_RD_DATA: begin
                if (m00_rvalid && m00_rready) begin
                    if (m00_rlast) begin
                        m00_rvalid   <= 1'b0;
                        m00_arready  <= 1'b1;
                        m00_rd_state <= S_RD_ADDR;
                    end else begin
                        m00_rd_beats <= m00_rd_beats - 1;
                        m00_rlast    <= (m00_rd_beats == 8'd1);
                        m00_rdata    <= m00_rdata + 1;
                    end
                end
            end
            default: m00_rd_state <= S_RD_IDLE;
        endcase
    end
end

// --------------------------------------------------------------------------
// AXI4 Slave Model – M01 (identical structure, different instance)
// --------------------------------------------------------------------------
wr_state_t m01_wr_state;
rd_state_t m01_rd_state;
logic [ID_WIDTH-1:0]   m01_saved_awid;
logic [7:0]            m01_beats_rem;
logic [ID_WIDTH-1:0]   m01_saved_arid;
logic [7:0]            m01_rd_beats;
logic [ADDR_WIDTH-1:0] m01_rd_base_addr;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        m01_awready    <= 1'b0;
        m01_wready     <= 1'b0;
        m01_bvalid     <= 1'b0;
        m01_bid        <= '0;
        m01_bresp      <= 2'b00;
        m01_buser      <= '0;
        m01_arready    <= 1'b0;
        m01_rvalid     <= 1'b0;
        m01_rid        <= '0;
        m01_rdata      <= '0;
        m01_rresp      <= 2'b00;
        m01_rlast      <= 1'b0;
        m01_ruser      <= '0;
        m01_wr_state   <= S_WR_IDLE;
        m01_rd_state   <= S_RD_IDLE;
    end else begin
        // ---- write path ----
        case (m01_wr_state)
            S_WR_IDLE: begin
                m01_awready  <= 1'b1;
                m01_wr_state <= S_WR_ADDR;
            end
            S_WR_ADDR: begin
                if (m01_awvalid && m01_awready) begin
                    m01_saved_awid <= m01_awid;
                    m01_beats_rem  <= m01_awlen;
                    m01_awready    <= 1'b0;
                    m01_wready     <= 1'b1;
                    m01_wr_state   <= S_WR_DATA;
                end
            end
            S_WR_DATA: begin
                if (m01_wvalid && m01_wready) begin
                    if (m01_wlast || m01_beats_rem == 0) begin
                        m01_wready   <= 1'b0;
                        m01_bvalid   <= 1'b1;
                        m01_bid      <= m01_saved_awid;
                        m01_bresp    <= 2'b00;
                        m01_wr_state <= S_WR_RESP;
                    end else begin
                        m01_beats_rem <= m01_beats_rem - 1;
                    end
                end
            end
            S_WR_RESP: begin
                if (m01_bready && m01_bvalid) begin
                    m01_bvalid   <= 1'b0;
                    m01_awready  <= 1'b1;
                    m01_wr_state <= S_WR_ADDR;
                end
            end
            default: m01_wr_state <= S_WR_IDLE;
        endcase

        // ---- read path ----
        case (m01_rd_state)
            S_RD_IDLE: begin
                m01_arready  <= 1'b1;
                m01_rd_state <= S_RD_ADDR;
            end
            S_RD_ADDR: begin
                if (m01_arvalid && m01_arready) begin
                    m01_saved_arid   <= m01_arid;
                    m01_rd_beats     <= m01_arlen;
                    m01_rd_base_addr <= m01_araddr;
                    m01_arready      <= 1'b0;
                    m01_rvalid       <= 1'b1;
                    m01_rid          <= m01_arid;
                    m01_rdata        <= {32'hB6B6_0000 | m01_araddr[31:0]};
                    m01_rresp        <= 2'b00;
                    m01_rlast        <= (m01_arlen == 8'd0);
                    m01_rd_state     <= S_RD_DATA;
                end
            end
            S_RD_DATA: begin
                if (m01_rvalid && m01_rready) begin
                    if (m01_rlast) begin
                        m01_rvalid   <= 1'b0;
                        m01_arready  <= 1'b1;
                        m01_rd_state <= S_RD_ADDR;
                    end else begin
                        m01_rd_beats <= m01_rd_beats - 1;
                        m01_rlast    <= (m01_rd_beats == 8'd1);
                        m01_rdata    <= m01_rdata + 1;
                    end
                end
            end
            default: m01_rd_state <= S_RD_IDLE;
        endcase
    end
end

// --------------------------------------------------------------------------
// Generic write transaction task
//   Drives the named S-port signals passed by reference.
//   addr selects the target master (M00 or M01).
// --------------------------------------------------------------------------
task automatic axi_write (
    // Port selection (0..3)
    input int            port,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data,
    input [ID_WIDTH-1:0]   tid,
    output logic           ok
);
    automatic int timeout = TIMEOUT_CYCLES;
    ok = 1;

    // Drive AW channel
    case (port)
        0: begin
            @(posedge clk);
            s00_awid = tid; s00_awaddr = addr; s00_awlen = 0;
            s00_awsize = 3'b011; s00_awburst = 2'b01;
            s00_awlock=0; s00_awcache=0; s00_awprot=0; s00_awqos=0; s00_awuser=0;
            s00_awvalid = 1;
            // Wait for awready
            while (!s00_awready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s00_awvalid = 0; return; end
            @(posedge clk);
            s00_awvalid = 0;
            // Drive W channel
            s00_wdata = data; s00_wstrb = 8'hFF; s00_wlast = 1; s00_wuser = 0;
            s00_wvalid = 1;
            while (!s00_wready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s00_wvalid = 0; s00_wlast = 0; return; end
            @(posedge clk);
            s00_wvalid = 0; s00_wlast = 0;
            // Wait for B channel
            s00_bready = 1;
            while (!s00_bvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            if (s00_bresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        1: begin
            @(posedge clk);
            s01_awid = tid; s01_awaddr = addr; s01_awlen = 0;
            s01_awsize = 3'b011; s01_awburst = 2'b01;
            s01_awlock=0; s01_awcache=0; s01_awprot=0; s01_awqos=0; s01_awuser=0;
            s01_awvalid = 1;
            while (!s01_awready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s01_awvalid = 0; return; end
            @(posedge clk);
            s01_awvalid = 0;
            s01_wdata = data; s01_wstrb = 8'hFF; s01_wlast = 1; s01_wuser = 0;
            s01_wvalid = 1;
            while (!s01_wready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s01_wvalid = 0; s01_wlast = 0; return; end
            @(posedge clk);
            s01_wvalid = 0; s01_wlast = 0;
            s01_bready = 1;
            while (!s01_bvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            if (s01_bresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        2: begin
            @(posedge clk);
            s02_awid = tid; s02_awaddr = addr; s02_awlen = 0;
            s02_awsize = 3'b011; s02_awburst = 2'b01;
            s02_awlock=0; s02_awcache=0; s02_awprot=0; s02_awqos=0; s02_awuser=0;
            s02_awvalid = 1;
            while (!s02_awready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s02_awvalid = 0; return; end
            @(posedge clk);
            s02_awvalid = 0;
            s02_wdata = data; s02_wstrb = 8'hFF; s02_wlast = 1; s02_wuser = 0;
            s02_wvalid = 1;
            while (!s02_wready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s02_wvalid = 0; s02_wlast = 0; return; end
            @(posedge clk);
            s02_wvalid = 0; s02_wlast = 0;
            s02_bready = 1;
            while (!s02_bvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            if (s02_bresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        3: begin
            @(posedge clk);
            s03_awid = tid; s03_awaddr = addr; s03_awlen = 0;
            s03_awsize = 3'b011; s03_awburst = 2'b01;
            s03_awlock=0; s03_awcache=0; s03_awprot=0; s03_awqos=0; s03_awuser=0;
            s03_awvalid = 1;
            while (!s03_awready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s03_awvalid = 0; return; end
            @(posedge clk);
            s03_awvalid = 0;
            s03_wdata = data; s03_wstrb = 8'hFF; s03_wlast = 1; s03_wuser = 0;
            s03_wvalid = 1;
            while (!s03_wready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s03_wvalid = 0; s03_wlast = 0; return; end
            @(posedge clk);
            s03_wvalid = 0; s03_wlast = 0;
            s03_bready = 1;
            while (!s03_bvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            if (s03_bresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        default: ok = 0;
    endcase
endtask

// --------------------------------------------------------------------------
// Generic read transaction task
// --------------------------------------------------------------------------
task automatic axi_read (
    input  int             port,
    input  [ADDR_WIDTH-1:0] addr,
    input  [ID_WIDTH-1:0]   tid,
    output [DATA_WIDTH-1:0] rdata_out,
    output logic            ok
);
    automatic int timeout = TIMEOUT_CYCLES;
    ok = 1;
    rdata_out = '0;

    case (port)
        0: begin
            @(posedge clk);
            s00_arid = tid; s00_araddr = addr; s00_arlen = 0;
            s00_arsize = 3'b011; s00_arburst = 2'b01;
            s00_arlock=0; s00_arcache=0; s00_arprot=0; s00_arqos=0; s00_aruser=0;
            s00_arvalid = 1;
            while (!s00_arready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s00_arvalid = 0; return; end
            @(posedge clk);
            s00_arvalid = 0;
            s00_rready = 1;
            while (!s00_rvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            rdata_out = s00_rdata;
            if (s00_rresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        1: begin
            @(posedge clk);
            s01_arid = tid; s01_araddr = addr; s01_arlen = 0;
            s01_arsize = 3'b011; s01_arburst = 2'b01;
            s01_arlock=0; s01_arcache=0; s01_arprot=0; s01_arqos=0; s01_aruser=0;
            s01_arvalid = 1;
            while (!s01_arready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s01_arvalid = 0; return; end
            @(posedge clk);
            s01_arvalid = 0;
            s01_rready = 1;
            while (!s01_rvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            rdata_out = s01_rdata;
            if (s01_rresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        2: begin
            @(posedge clk);
            s02_arid = tid; s02_araddr = addr; s02_arlen = 0;
            s02_arsize = 3'b011; s02_arburst = 2'b01;
            s02_arlock=0; s02_arcache=0; s02_arprot=0; s02_arqos=0; s02_aruser=0;
            s02_arvalid = 1;
            while (!s02_arready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s02_arvalid = 0; return; end
            @(posedge clk);
            s02_arvalid = 0;
            s02_rready = 1;
            while (!s02_rvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            rdata_out = s02_rdata;
            if (s02_rresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        3: begin
            @(posedge clk);
            s03_arid = tid; s03_araddr = addr; s03_arlen = 0;
            s03_arsize = 3'b011; s03_arburst = 2'b01;
            s03_arlock=0; s03_arcache=0; s03_arprot=0; s03_arqos=0; s03_aruser=0;
            s03_arvalid = 1;
            while (!s03_arready && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; s03_arvalid = 0; return; end
            @(posedge clk);
            s03_arvalid = 0;
            s03_rready = 1;
            while (!s03_rvalid && timeout > 0) begin @(posedge clk); timeout--; end
            if (timeout == 0) begin ok = 0; return; end
            rdata_out = s03_rdata;
            if (s03_rresp != 2'b00) ok = 0;
            @(posedge clk);
        end
        default: ok = 0;
    endcase
endtask

// --------------------------------------------------------------------------
// Main test sequence
// --------------------------------------------------------------------------
logic             txn_ok;
logic [DATA_WIDTH-1:0] rd_data;

initial begin
    // ------------------------------------------------------------------
    // Initialise all S-port outputs
    // ------------------------------------------------------------------
    idle_s00(); idle_s01(); idle_s02(); idle_s03();
    // ------------------------------------------------------------------
    // TEST 1: Clock & Reset
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 1: Clock and Reset");
    rst = 1;
    repeat (10) @(posedge clk);
    rst = 0;
    repeat (5)  @(posedge clk);

    // After de-assert, verify awready lines from slave models come up
    // (slave models start in S_WR_IDLE → assert awready one cycle later)
    repeat (5) @(posedge clk);
    if (m00_awready && m01_awready)
        pass_check("T1 – Slave models respond after reset");
    else
        fail_check("T1 – Slave models respond after reset",
                   "m00_awready or m01_awready not high");

    // ------------------------------------------------------------------
    // TEST 2: Write from S00 → M00 (address in 0x0000_0000 region)
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 2: Write S00 -> M00 (addr 0x0000_0100)");
    axi_write(0, 32'h0000_0100, 64'hDEAD_BEEF_1234_5678, 8'h01, txn_ok);
    if (txn_ok) pass_check("T2 – S00 write to M00 region OKAY");
    else        fail_check("T2 – S00 write to M00 region", "Transaction did not complete or bresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 3: Write from S00 → M01 (address in 0x4000_0000 region)
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 3: Write S00 -> M01 (addr 0x4000_0200)");
    axi_write(0, 32'h4000_0200, 64'hCAFE_BABE_ABCD_EF01, 8'h02, txn_ok);
    if (txn_ok) pass_check("T3 – S00 write to M01 region OKAY");
    else        fail_check("T3 – S00 write to M01 region", "Transaction did not complete or bresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 4: Write from S01 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 4: Write S01 -> M00 (addr 0x0000_0300)");
    axi_write(1, 32'h0000_0300, 64'h1111_2222_3333_4444, 8'h11, txn_ok);
    if (txn_ok) pass_check("T4 – S01 write to M00 region OKAY");
    else        fail_check("T4 – S01 write to M00 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 5: Write from S01 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 5: Write S01 -> M01 (addr 0x4000_0400)");
    axi_write(1, 32'h4000_0400, 64'h5555_6666_7777_8888, 8'h12, txn_ok);
    if (txn_ok) pass_check("T5 – S01 write to M01 region OKAY");
    else        fail_check("T5 – S01 write to M01 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 6: Write from S02 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 6: Write S02 -> M00 (addr 0x0000_0500)");
    axi_write(2, 32'h0000_0500, 64'hAAAA_BBBB_CCCC_DDDD, 8'h21, txn_ok);
    if (txn_ok) pass_check("T6 – S02 write to M00 region OKAY");
    else        fail_check("T6 – S02 write to M00 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 7: Write from S02 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 7: Write S02 -> M01 (addr 0x4000_0600)");
    axi_write(2, 32'h4000_0600, 64'hEEEE_FFFF_0000_1111, 8'h22, txn_ok);
    if (txn_ok) pass_check("T7 – S02 write to M01 region OKAY");
    else        fail_check("T7 – S02 write to M01 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 8: Write from S03 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 8: Write S03 -> M00 (addr 0x0000_0700)");
    axi_write(3, 32'h0000_0700, 64'h1234_5678_9ABC_DEF0, 8'h31, txn_ok);
    if (txn_ok) pass_check("T8 – S03 write to M00 region OKAY");
    else        fail_check("T8 – S03 write to M00 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 9: Write from S03 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 9: Write S03 -> M01 (addr 0x4000_0800)");
    axi_write(3, 32'h4000_0800, 64'hFEDC_BA98_7654_3210, 8'h32, txn_ok);
    if (txn_ok) pass_check("T9 – S03 write to M01 region OKAY");
    else        fail_check("T9 – S03 write to M01 region", "Transaction timed out or bad bresp");

    // ------------------------------------------------------------------
    // TEST 10: Read from S00 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 10: Read S00 -> M00 (addr 0x0000_1000)");
    axi_read(0, 32'h0000_1000, 8'h41, rd_data, txn_ok);
    if (txn_ok) pass_check("T10 – S00 read from M00 OKAY");
    else        fail_check("T10 – S00 read from M00", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 11: Read from S00 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 11: Read S00 -> M01 (addr 0x4000_1000)");
    axi_read(0, 32'h4000_1000, 8'h42, rd_data, txn_ok);
    if (txn_ok) pass_check("T11 – S00 read from M01 OKAY");
    else        fail_check("T11 – S00 read from M01", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 12: Read from S01 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 12: Read S01 -> M00 (addr 0x0000_2000)");
    axi_read(1, 32'h0000_2000, 8'h51, rd_data, txn_ok);
    if (txn_ok) pass_check("T12 – S01 read from M00 OKAY");
    else        fail_check("T12 – S01 read from M00", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 13: Read from S01 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 13: Read S01 -> M01 (addr 0x4000_2000)");
    axi_read(1, 32'h4000_2000, 8'h52, rd_data, txn_ok);
    if (txn_ok) pass_check("T13 – S01 read from M01 OKAY");
    else        fail_check("T13 – S01 read from M01", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 14: Read from S02 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 14: Read S02 -> M00 (addr 0x0000_3000)");
    axi_read(2, 32'h0000_3000, 8'h61, rd_data, txn_ok);
    if (txn_ok) pass_check("T14 – S02 read from M00 OKAY");
    else        fail_check("T14 – S02 read from M00", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 15: Read from S02 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 15: Read S02 -> M01 (addr 0x4000_3000)");
    axi_read(2, 32'h4000_3000, 8'h62, rd_data, txn_ok);
    if (txn_ok) pass_check("T15 – S02 read from M01 OKAY");
    else        fail_check("T15 – S02 read from M01", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 16: Read from S03 → M00
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 16: Read S03 -> M00 (addr 0x0000_4000)");
    axi_read(3, 32'h0000_4000, 8'h71, rd_data, txn_ok);
    if (txn_ok) pass_check("T16 – S03 read from M00 OKAY");
    else        fail_check("T16 – S03 read from M00", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 17: Read from S03 → M01
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");
    $display("TEST 17: Read S03 -> M01 (addr 0x4000_4000)");
    axi_read(3, 32'h4000_4000, 8'h72, rd_data, txn_ok);
    if (txn_ok) pass_check("T17 – S03 read from M01 OKAY");
    else        fail_check("T17 – S03 read from M01", "Timed out or rresp != OKAY");

    // ------------------------------------------------------------------
    // TEST 18: Verify M00 address region – awaddr must be < 0x4000_0000
    //          while M01 address region – awaddr must be >= 0x4000_0000
    //          (checked by observing which slave model becomes active)
    // ------------------------------------------------------------------
    $display("------------------------------------------------------");

    idle_s00(); idle_s01(); idle_s02(); idle_s03();
    $display("TEST 18: Address-region routing verification");
    begin
        logic ok;

        // S00 -> M00
        axi_write(0, 32'h0000_00A0, 64'hABCD_EF00_1234_5678, 8'hA1, ok);
        if (ok)
            pass_check("T18a – S00 write to M00 region OKAY");
        else
            fail_check("T18a – S00 write to M00 region", "AXI write transaction failed");

        // S00 -> M01
        axi_write(0, 32'h4000_00B0, 64'hBEEF_CAFE_DEAD_0000, 8'hA2, ok);
        if (ok)
            pass_check("T18b – S00 write to M01 region OKAY");
        else
            fail_check("T18b – S00 write to M01 region", "AXI write transaction failed");
    end

    repeat (20) @(posedge clk);

    // ------------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------------
    $display("======================================================");
    $display("SIMULATION COMPLETE");
    $display("  PASS count : %0d", pass_cnt);
    $display("  FAIL count : %0d", fail_cnt);
    if (fail_cnt == 0)
        $display("  OVERALL    : *** PASS ***");
    else
        $display("  OVERALL    : *** FAIL ***");
    $display("======================================================");
    $finish;
end

// --------------------------------------------------------------------------
// Global timeout guard
// --------------------------------------------------------------------------
initial begin
    #(CLK_PERIOD * 100000);
    $display("[FAIL] GLOBAL TIMEOUT – simulation exceeded %0d cycles",
             100000);
    $finish;
end

endmodule
