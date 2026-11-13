// =============================================================================
// File        : crc32_top.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : CRC-32 IP top-level integration module.
//
//   Integrates:
//     - crc32_axi_lite_slave : processor configuration interface
//     - crc32_controller     : state machine and orchestration
//     - crc32_byte_core      : CRC-32/Ethernet byte-processing engine
//     - crc32_axi_read_master: 64-bit AXI4 memory read interface
//
//   External interfaces:
//     AXI4-Lite slave  (32-bit) : processor register access
//     AXI4 read master (64-bit) : memory data fetching
//     Clock, active-low reset   : single synchronous domain
//     IRQ output                : completion / error interrupt
//
//   Parameters:
//     AXIL_ADDR_WIDTH : AXI4-Lite address width (default 32)
//     AXIM_ADDR_WIDTH : AXI4 master address width (default 32, = interconnect)
//     AXIM_ID_WIDTH   : AXI4 master ID width (default 8, = interconnect)
//     MAX_BURST_LEN   : AXI4 read master max burst length in beats (default 16)
//
//   SoC integration notes:
//     - Connect s_axi_* to one AXI4-Lite slave port of the SoC interconnect.
//     - Connect m_axi_* to one AXI4 master port of the SoC interconnect.
//     - The base address of this peripheral is assigned by the SoC address map
//       (not hardcoded here).
//     - The interrupt output (irq_o) connects to the processor interrupt input.
//     - A single clock domain is assumed; no CDC crossings are required unless
//       the interconnect runs at a different frequency.
//     - rst_n is active-low synchronous reset.
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module crc32_top
  import crc32_pkg::*;
#(
  parameter int unsigned AXIL_ADDR_WIDTH = 32,  // AXI4-Lite address width
  parameter int unsigned AXIM_ADDR_WIDTH = 32,  // AXI4 master address width
  parameter int unsigned AXIM_ID_WIDTH   = 8,   // AXI4 master ID width
  parameter int unsigned MAX_BURST_LEN   = 16   // AXI4 read master burst length
)(
  input  logic                          clk,
  input  logic                          rst_n,    // active-low synchronous reset

  // --------------------------------------------------------------------------
  // AXI4-Lite Slave Interface (processor → CRC register access)
  // --------------------------------------------------------------------------
  input  logic [AXIL_ADDR_WIDTH-1:0]    s_axi_awaddr,
  input  logic [2:0]                    s_axi_awprot,
  input  logic                          s_axi_awvalid,
  output logic                          s_axi_awready,

  input  logic [31:0]                   s_axi_wdata,
  input  logic [3:0]                    s_axi_wstrb,
  input  logic                          s_axi_wvalid,
  output logic                          s_axi_wready,

  output logic [1:0]                    s_axi_bresp,
  output logic                          s_axi_bvalid,
  input  logic                          s_axi_bready,

  input  logic [AXIL_ADDR_WIDTH-1:0]    s_axi_araddr,
  input  logic [2:0]                    s_axi_arprot,
  input  logic                          s_axi_arvalid,
  output logic                          s_axi_arready,

  output logic [31:0]                   s_axi_rdata,
  output logic [1:0]                    s_axi_rresp,
  output logic                          s_axi_rvalid,
  input  logic                          s_axi_rready,

  // --------------------------------------------------------------------------
  // AXI4 Read Master Interface (CRC → memory)
  // --------------------------------------------------------------------------
  output logic [AXIM_ID_WIDTH-1:0]      m_axi_arid,
  output logic [AXIM_ADDR_WIDTH-1:0]    m_axi_araddr,
  output logic [7:0]                    m_axi_arlen,
  output logic [2:0]                    m_axi_arsize,
  output logic [1:0]                    m_axi_arburst,
  output logic                          m_axi_arlock,
  output logic [3:0]                    m_axi_arcache,
  output logic [2:0]                    m_axi_arprot,
  output logic [3:0]                    m_axi_arqos,
  output logic                          m_axi_arvalid,
  input  logic                          m_axi_arready,

  input  logic [AXIM_ID_WIDTH-1:0]      m_axi_rid,
  input  logic [63:0]                   m_axi_rdata,
  input  logic [1:0]                    m_axi_rresp,
  input  logic                          m_axi_rlast,
  input  logic                          m_axi_rvalid,
  output logic                          m_axi_rready,

  // --------------------------------------------------------------------------
  // Interrupt & Monitoring outputs
  // --------------------------------------------------------------------------
  output logic                          irq_o,
  output logic                          crc_busy,
  output logic                          crc_done,
  output logic                          crc_pass,
  output logic                          crc_fail
);

  // --------------------------------------------------------------------------
  // Internal wires between submodules
  // --------------------------------------------------------------------------

  // Register interface (AXI-Lite slave → controller)
  logic        reg_start;
  logic        reg_sw_reset;
  logic        reg_ie;
  logic [31:0] reg_src_addr;
  logic [31:0] reg_src_addr_hi;   // unused in current HW, wired through
  logic [31:0] reg_length;
  logic [31:0] reg_expected;
  logic        reg_irq_clear;

  // Status interface (controller → AXI-Lite slave)
  logic [4:0]  reg_status;
  logic [31:0] reg_computed;
  logic        reg_irq_status;

  // Read master control (controller → AXI4 read master)
  logic        rm_start;
  logic [31:0] rm_base_addr;
  logic [31:0] rm_byte_count;
  logic        rm_done;
  logic        rm_error;

  // Byte stream (AXI4 read master → controller → CRC core)
  logic [7:0]  byte_data;
  logic        byte_valid;
  logic        byte_ready;

  // CRC core control (controller → CRC byte core)
  logic        crc_init;
  logic        crc_valid;
  logic [7:0]  crc_data;
  logic [31:0] crc_result;
  logic [31:0] crc_raw;          // unused at top but available for debug

  // --------------------------------------------------------------------------
  // AXI4-Lite Slave
  // --------------------------------------------------------------------------
  crc32_axi_lite_slave #(
    .ADDR_WIDTH (AXIL_ADDR_WIDTH)
  ) u_axi_lite_slave (
    .clk              (clk),
    .rst_n            (rst_n),

    .s_axi_awaddr     (s_axi_awaddr),
    .s_axi_awprot     (s_axi_awprot),
    .s_axi_awvalid    (s_axi_awvalid),
    .s_axi_awready    (s_axi_awready),

    .s_axi_wdata      (s_axi_wdata),
    .s_axi_wstrb      (s_axi_wstrb),
    .s_axi_wvalid     (s_axi_wvalid),
    .s_axi_wready     (s_axi_wready),

    .s_axi_bresp      (s_axi_bresp),
    .s_axi_bvalid     (s_axi_bvalid),
    .s_axi_bready     (s_axi_bready),

    .s_axi_araddr     (s_axi_araddr),
    .s_axi_arprot     (s_axi_arprot),
    .s_axi_arvalid    (s_axi_arvalid),
    .s_axi_arready    (s_axi_arready),

    .s_axi_rdata      (s_axi_rdata),
    .s_axi_rresp      (s_axi_rresp),
    .s_axi_rvalid     (s_axi_rvalid),
    .s_axi_rready     (s_axi_rready),

    .reg_start_o      (reg_start),
    .reg_sw_reset_o   (reg_sw_reset),
    .reg_ie_o         (reg_ie),
    .reg_src_addr_o   (reg_src_addr),
    .reg_src_addr_hi_o(reg_src_addr_hi),
    .reg_length_o     (reg_length),
    .reg_expected_o   (reg_expected),
    .reg_irq_clear_o  (reg_irq_clear),

    .reg_status_i     (reg_status),
    .reg_computed_i   (reg_computed),
    .reg_irq_status_i (reg_irq_status)
  );

  // --------------------------------------------------------------------------
  // CRC Controller
  // --------------------------------------------------------------------------
  crc32_controller u_controller (
    .clk              (clk),
    .rst_n            (rst_n),

    .reg_start_i      (reg_start),
    .reg_sw_reset_i   (reg_sw_reset),
    .reg_ie_i         (reg_ie),
    .reg_src_addr_i   (reg_src_addr),
    .reg_length_i     (reg_length),
    .reg_expected_i   (reg_expected),
    .reg_irq_clear_i  (reg_irq_clear),

    .reg_status_o     (reg_status),
    .reg_computed_o   (reg_computed),
    .reg_irq_status_o (reg_irq_status),

    .rm_start_o       (rm_start),
    .rm_base_addr_o   (rm_base_addr),
    .rm_byte_count_o  (rm_byte_count),
    .rm_done_i        (rm_done),
    .rm_error_i       (rm_error),

    .byte_data_i      (byte_data),
    .byte_valid_i     (byte_valid),
    .byte_ready_o     (byte_ready),

    .crc_init_o       (crc_init),
    .crc_valid_o      (crc_valid),
    .crc_data_o       (crc_data),
    .crc_result_i     (crc_result),

    .irq_o            (irq_o)
  );

  // --------------------------------------------------------------------------
  // CRC-32 Byte Core
  // --------------------------------------------------------------------------
  crc32_byte_core u_crc_core (
    .clk      (clk),
    .rst_n    (rst_n),
    .init_i   (crc_init),
    .valid_i  (crc_valid),
    .data_i   (crc_data),
    .crc_o    (crc_result),
    .crc_raw_o(crc_raw)
  );

  // --------------------------------------------------------------------------
  // AXI4 Read Master
  // --------------------------------------------------------------------------
  crc32_axi_read_master #(
    .ADDR_WIDTH    (AXIM_ADDR_WIDTH),
    .ID_WIDTH      (AXIM_ID_WIDTH),
    .MAX_BURST_LEN (MAX_BURST_LEN)
  ) u_axi_read_master (
    .clk            (clk),
    .rst_n          (rst_n),

    .start_i        (rm_start),
    .base_addr_i    (rm_base_addr),
    .byte_count_i   (rm_byte_count),
    .done_o         (rm_done),
    .error_o        (rm_error),

    .byte_data_o    (byte_data),
    .byte_valid_o   (byte_valid),
    .byte_ready_i   (byte_ready),

    .m_axi_arid     (m_axi_arid),
    .m_axi_araddr   (m_axi_araddr),
    .m_axi_arlen    (m_axi_arlen),
    .m_axi_arsize   (m_axi_arsize),
    .m_axi_arburst  (m_axi_arburst),
    .m_axi_arlock   (m_axi_arlock),
    .m_axi_arcache  (m_axi_arcache),
    .m_axi_arprot   (m_axi_arprot),
    .m_axi_arqos    (m_axi_arqos),
    .m_axi_arvalid  (m_axi_arvalid),
    .m_axi_arready  (m_axi_arready),

    .m_axi_rid      (m_axi_rid),
    .m_axi_rdata    (m_axi_rdata),
    .m_axi_rresp    (m_axi_rresp),
    .m_axi_rlast    (m_axi_rlast),
    .m_axi_rvalid   (m_axi_rvalid),
    .m_axi_rready   (m_axi_rready)
  );

  // --------------------------------------------------------------------------
  // Hardware status and monitoring outputs
  // --------------------------------------------------------------------------
  assign crc_busy = reg_status[0];
  assign crc_done = reg_status[1];
  assign crc_pass = reg_status[2];
  assign crc_fail = reg_status[3];

endmodule : crc32_top

`default_nettype wire
