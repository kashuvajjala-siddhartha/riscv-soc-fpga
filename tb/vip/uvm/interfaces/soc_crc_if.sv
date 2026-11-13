`timescale 1ns/1ps

interface soc_crc_if(input logic clk);

  logic rst_n;

  // AXI4-Lite slave interface
  logic [31:0] s_axi_awaddr;
  logic [2:0]  s_axi_awprot;
  logic        s_axi_awvalid;
  logic        s_axi_awready;

  logic [31:0] s_axi_wdata;
  logic [3:0]  s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;

  logic [1:0]  s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;

  logic [31:0] s_axi_araddr;
  logic [2:0]  s_axi_arprot;
  logic        s_axi_arvalid;
  logic        s_axi_arready;

  logic [31:0] s_axi_rdata;
  logic [1:0]  s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;

  // AXI4 read master interface
  logic [7:0]  m_axi_arid;
  logic [31:0] m_axi_araddr;
  logic [7:0]  m_axi_arlen;
  logic [2:0]  m_axi_arsize;
  logic [1:0]  m_axi_arburst;
  logic        m_axi_arlock;
  logic [3:0]  m_axi_arcache;
  logic [2:0]  m_axi_arprot;
  logic [3:0]  m_axi_arqos;
  logic        m_axi_arvalid;
  logic        m_axi_arready;

  logic [7:0]  m_axi_rid;
  logic [63:0] m_axi_rdata;
  logic [1:0]  m_axi_rresp;
  logic        m_axi_rlast;
  logic        m_axi_rvalid;
  logic        m_axi_rready;

  // Interrupt
  logic irq_o;

    // Driver clocking block
  clocking drv_cb @(posedge clk);
    default input #1step output #1ns;

    output rst_n;

    output s_axi_awaddr, s_axi_awprot, s_axi_awvalid;
    input  s_axi_awready;

    output s_axi_wdata, s_axi_wstrb, s_axi_wvalid;
    input  s_axi_wready;

    input  s_axi_bresp, s_axi_bvalid;
    output s_axi_bready;

    output s_axi_araddr, s_axi_arprot, s_axi_arvalid;
    input  s_axi_arready;

    input  s_axi_rdata, s_axi_rresp, s_axi_rvalid;
    output s_axi_rready;

    input m_axi_arid, m_axi_araddr, m_axi_arlen;
    input m_axi_arsize, m_axi_arburst, m_axi_arlock;
    input m_axi_arcache, m_axi_arprot, m_axi_arqos;
    input m_axi_arvalid;
    output m_axi_arready;

    input m_axi_rid, m_axi_rdata, m_axi_rresp;
    input m_axi_rlast, m_axi_rvalid;
    output m_axi_rready;

    input irq_o;
  endclocking

  // Monitor clocking block
  clocking mon_cb @(posedge clk);
    default input #1step;

    input rst_n;

    input s_axi_awaddr, s_axi_awprot, s_axi_awvalid, s_axi_awready;
    input s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready;
    input s_axi_bresp, s_axi_bvalid, s_axi_bready;
    input s_axi_araddr, s_axi_arprot, s_axi_arvalid, s_axi_arready;
    input s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready;

    input m_axi_arid, m_axi_araddr, m_axi_arlen;
    input m_axi_arsize, m_axi_arburst, m_axi_arlock;
    input m_axi_arcache, m_axi_arprot, m_axi_arqos;
    input m_axi_arvalid, m_axi_arready;

    input m_axi_rid, m_axi_rdata, m_axi_rresp;
    input m_axi_rlast, m_axi_rvalid, m_axi_rready;

    input irq_o;
  endclocking

  modport DUT (
    input clk, rst_n,

    input s_axi_awaddr, s_axi_awprot, s_axi_awvalid,
    output s_axi_awready,

    input s_axi_wdata, s_axi_wstrb, s_axi_wvalid,
    output s_axi_wready,

    output s_axi_bresp, s_axi_bvalid,
    input s_axi_bready,

    input s_axi_araddr, s_axi_arprot, s_axi_arvalid,
    output s_axi_arready,

    output s_axi_rdata, s_axi_rresp, s_axi_rvalid,
    input s_axi_rready,

    output m_axi_arid, m_axi_araddr, m_axi_arlen,
    output m_axi_arsize, m_axi_arburst, m_axi_arlock,
    output m_axi_arcache, m_axi_arprot, m_axi_arqos,
    output m_axi_arvalid,
    input m_axi_arready,

    input m_axi_rid, m_axi_rdata, m_axi_rresp,
    input m_axi_rlast, m_axi_rvalid,
    output m_axi_rready,

    output irq_o
  );

endinterface
