// =============================================================================
// File        : crc32_axi_lite_slave.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : AXI4-Lite slave interface for the CRC-32 IP.
//
//   Provides memory-mapped access to the CRC-32 control and status registers.
//   The AXI4-Lite data width is 32 bits.  Address width is parameterisable
//   (default 32 bits, matching the SoC interconnect ADDR_WIDTH).
//
//   Strictly follows AXI4-Lite protocol:
//   - Write: AW and W channels are independent; module waits for both.
//   - Write response (B channel) is issued after both AW and W received.
//   - Read: AR accepted; R response follows one cycle later.
//   - Byte strobes on writes are honoured.
//   - Unsupported addresses return SLVERR.
//
//   Register map (peripheral-relative offsets, from crc32_pkg):
//     0x00  CONTROL      RW
//     0x04  STATUS       RO
//     0x08  SRC_ADDR_LO  RW
//     0x0C  SRC_ADDR_HI  RW
//     0x10  LENGTH       RW
//     0x14  EXPECTED_CRC RW
//     0x18  COMPUTED_CRC RO
//     0x1C  IRQ_ENABLE   RW
//     0x20  IRQ_STATUS   R/W1C
//
//   Interface to controller:
//     reg_start_o      : pulse — initiates a CRC run (one cycle)
//     reg_sw_reset_o   : pulse — software reset (one cycle)
//     reg_ie_o         : interrupt enable (level)
//     reg_src_addr_o   : source address [31:0]
//     reg_src_addr_hi_o: source address [63:32] (reserved, pass-through)
//     reg_length_o     : transfer length in bytes
//     reg_expected_o   : expected CRC value
//     reg_status_i     : {ERROR,FAIL,PASS,DONE,BUSY} from controller
//     reg_computed_i   : computed CRC from controller
//     reg_irq_status_i : interrupt status from controller
//     reg_irq_clear_o  : W1C clear pulse for interrupt status
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module crc32_axi_lite_slave
  import crc32_pkg::*;
#(
  parameter int unsigned ADDR_WIDTH = 32  // AXI address bus width
)(
  input  logic                   clk,
  input  logic                   rst_n,     // active-low synchronous reset

  // --------------------------------------------------------------------------
  // AXI4-Lite Slave Interface (32-bit data, ADDR_WIDTH address)
  // --------------------------------------------------------------------------

  // Write address channel
  input  logic [ADDR_WIDTH-1:0]  s_axi_awaddr,
  input  logic [2:0]             s_axi_awprot,
  input  logic                   s_axi_awvalid,
  output logic                   s_axi_awready,

  // Write data channel
  input  logic [31:0]            s_axi_wdata,
  input  logic [3:0]             s_axi_wstrb,
  input  logic                   s_axi_wvalid,
  output logic                   s_axi_wready,

  // Write response channel
  output logic [1:0]             s_axi_bresp,
  output logic                   s_axi_bvalid,
  input  logic                   s_axi_bready,

  // Read address channel
  input  logic [ADDR_WIDTH-1:0]  s_axi_araddr,
  input  logic [2:0]             s_axi_arprot,
  input  logic                   s_axi_arvalid,
  output logic                   s_axi_arready,

  // Read data channel
  output logic [31:0]            s_axi_rdata,
  output logic [1:0]             s_axi_rresp,
  output logic                   s_axi_rvalid,
  input  logic                   s_axi_rready,

  // --------------------------------------------------------------------------
  // Register interface to CRC controller
  // --------------------------------------------------------------------------

  // Outputs to controller
  output logic        reg_start_o,
  output logic        reg_sw_reset_o,
  output logic        reg_ie_o,
  output logic [31:0] reg_src_addr_o,
  output logic [31:0] reg_src_addr_hi_o,
  output logic [31:0] reg_length_o,
  output logic [31:0] reg_expected_o,
  output logic        reg_irq_clear_o,

  // Inputs from controller
  input  logic [4:0]  reg_status_i,     // [4]=ERROR [3]=FAIL [2]=PASS [1]=DONE [0]=BUSY
  input  logic [31:0] reg_computed_i,
  input  logic        reg_irq_status_i
);

  // --------------------------------------------------------------------------
  // Register storage
  // --------------------------------------------------------------------------
  logic [31:0] ctrl_reg;        // CONTROL
  logic [31:0] src_addr_lo_reg; // SRC_ADDR_LO
  logic [31:0] src_addr_hi_reg; // SRC_ADDR_HI
  logic [31:0] length_reg;      // LENGTH
  logic [31:0] expected_reg;    // EXPECTED_CRC
  logic [31:0] irq_enable_reg;  // IRQ_ENABLE

  // --------------------------------------------------------------------------
  // AXI write state machine
  // AW and W channels are independent; we latch whichever arrives first.
  // --------------------------------------------------------------------------
  logic        aw_pending;      // AW address has been latched
  logic        w_pending;       // W data has been latched
  logic [7:0]  aw_addr_lat;     // latched lower 8 bits of write address
  logic [31:0] w_data_lat;      // latched write data
  logic [3:0]  w_strb_lat;      // latched write strobes
  logic        write_do;        // both AW and W are available — perform write
  logic        wr_addr_ok;      // write address is in the valid range

  // --------------------------------------------------------------------------
  // AXI read state machine
  // --------------------------------------------------------------------------
  logic        ar_pending;
  logic [7:0]  ar_addr_lat;
  logic        rd_addr_ok;

  // --------------------------------------------------------------------------
  // Pulse output registers (hold for one cycle only)
  // --------------------------------------------------------------------------
  logic reg_start_r;
  logic reg_sw_reset_r;
  logic reg_irq_clear_r;

  // --------------------------------------------------------------------------
  // Write address capture
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      aw_pending  <= 1'b0;
      aw_addr_lat <= '0;
    end else begin
      if (s_axi_awvalid && s_axi_awready && !write_do) begin
        aw_pending  <= 1'b1;
        aw_addr_lat <= s_axi_awaddr[7:0];
      end else if (write_do) begin
        aw_pending  <= 1'b0;
      end
    end
  end

  // --------------------------------------------------------------------------
  // Write data capture
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      w_pending  <= 1'b0;
      w_data_lat <= '0;
      w_strb_lat <= '0;
    end else begin
      if (s_axi_wvalid && s_axi_wready && !write_do) begin
        w_pending  <= 1'b1;
        w_data_lat <= s_axi_wdata;
        w_strb_lat <= s_axi_wstrb;
      end else if (write_do) begin
        w_pending  <= 1'b0;
      end
    end
  end

  // AW and W channel ready: accept whenever not already holding one
  assign s_axi_awready = !aw_pending;
  assign s_axi_wready  = !w_pending;

  // Both address and data are available (either just arrived or already latched)
  wire aw_this_cycle = (s_axi_awvalid && s_axi_awready);
  wire w_this_cycle  = (s_axi_wvalid  && s_axi_wready);

  wire aw_avail = aw_pending | aw_this_cycle;
  wire w_avail  = w_pending  | w_this_cycle;

  // Effective address and data for the write operation
  wire [7:0]  eff_aw_addr = aw_pending ? aw_addr_lat : s_axi_awaddr[7:0];
  wire [31:0] eff_w_data  = w_pending  ? w_data_lat  : s_axi_wdata;
  wire [3:0]  eff_w_strb  = w_pending  ? w_strb_lat  : s_axi_wstrb;

  // Perform write when both are available
  assign write_do = aw_avail && w_avail;

  // Address decode for writes
  assign wr_addr_ok = (eff_aw_addr == REG_CONTROL)     ||
                      (eff_aw_addr == REG_SRC_ADDR_LO)  ||
                      (eff_aw_addr == REG_SRC_ADDR_HI)  ||
                      (eff_aw_addr == REG_LENGTH)        ||
                      (eff_aw_addr == REG_EXPECTED_CRC)  ||
                      (eff_aw_addr == REG_IRQ_ENABLE)    ||
                      (eff_aw_addr == REG_IRQ_STATUS);

  // --------------------------------------------------------------------------
  // Byte-strobe application helper function
  // --------------------------------------------------------------------------
  function automatic logic [31:0] apply_strobe(
    input logic [31:0] old_val,
    input logic [31:0] new_val,
    input logic [3:0]  strb
  );
    logic [31:0] result;
    result = old_val;
    for (int i = 0; i < 4; i++) begin
      if (strb[i]) result[i*8 +: 8] = new_val[i*8 +: 8];
    end
    return result;
  endfunction

  // --------------------------------------------------------------------------
  // Register write logic
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    // Default: clear pulse signals
    reg_start_r     <= 1'b0;
    reg_sw_reset_r  <= 1'b0;
    reg_irq_clear_r <= 1'b0;

    if (!rst_n) begin
      ctrl_reg        <= '0;
      src_addr_lo_reg <= '0;
      src_addr_hi_reg <= '0;
      length_reg      <= '0;
      expected_reg    <= '0;
      irq_enable_reg  <= '0;
    end else if (write_do) begin
      case (eff_aw_addr)
        REG_CONTROL: begin
          ctrl_reg <= apply_strobe(ctrl_reg, eff_w_data, eff_w_strb);
          // START bit: pulse for one cycle
          if (eff_w_strb[0] && eff_w_data[CTRL_START_BIT])
            reg_start_r <= 1'b1;
          // RESET bit: pulse for one cycle
          if (eff_w_strb[0] && eff_w_data[CTRL_RESET_BIT])
            reg_sw_reset_r <= 1'b1;
        end
        REG_SRC_ADDR_LO:  src_addr_lo_reg <= apply_strobe(src_addr_lo_reg, eff_w_data, eff_w_strb);
        REG_SRC_ADDR_HI:  src_addr_hi_reg <= apply_strobe(src_addr_hi_reg, eff_w_data, eff_w_strb);
        REG_LENGTH:        length_reg      <= apply_strobe(length_reg,      eff_w_data, eff_w_strb);
        REG_EXPECTED_CRC:  expected_reg    <= apply_strobe(expected_reg,    eff_w_data, eff_w_strb);
        REG_IRQ_ENABLE:    irq_enable_reg  <= apply_strobe(irq_enable_reg,  eff_w_data, eff_w_strb);
        REG_IRQ_STATUS: begin
          // Write-one-to-clear
          if (eff_w_strb[0] && eff_w_data[IRQ_DONE_BIT])
            reg_irq_clear_r <= 1'b1;
        end
        default: ; // silently ignore writes to read-only or reserved registers
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // Write response (B channel)
  // --------------------------------------------------------------------------
  logic bvalid_r;
  logic [1:0] bresp_r;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      bvalid_r <= 1'b0;
      bresp_r  <= AXI_RESP_OKAY;
    end else begin
      if (write_do && !bvalid_r) begin
        bvalid_r <= 1'b1;
        bresp_r  <= wr_addr_ok ? AXI_RESP_OKAY : AXI_RESP_SLVERR;
      end else if (bvalid_r && s_axi_bready) begin
        bvalid_r <= 1'b0;
      end
    end
  end

  assign s_axi_bvalid = bvalid_r;
  assign s_axi_bresp  = bresp_r;

  // --------------------------------------------------------------------------
  // Read address capture
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      ar_pending  <= 1'b0;
      ar_addr_lat <= '0;
    end else begin
      if (s_axi_arvalid && s_axi_arready) begin
        ar_pending  <= 1'b1;
        ar_addr_lat <= s_axi_araddr[7:0];
      end else if (s_axi_rvalid && s_axi_rready) begin
        ar_pending  <= 1'b0;
      end
    end
  end

  assign s_axi_arready = !ar_pending;

  // Address decode for reads
  assign rd_addr_ok = (ar_addr_lat == REG_CONTROL)     ||
                      (ar_addr_lat == REG_STATUS)       ||
                      (ar_addr_lat == REG_SRC_ADDR_LO)  ||
                      (ar_addr_lat == REG_SRC_ADDR_HI)  ||
                      (ar_addr_lat == REG_LENGTH)        ||
                      (ar_addr_lat == REG_EXPECTED_CRC)  ||
                      (ar_addr_lat == REG_COMPUTED_CRC)  ||
                      (ar_addr_lat == REG_IRQ_ENABLE)    ||
                      (ar_addr_lat == REG_IRQ_STATUS);

  // --------------------------------------------------------------------------
  // Read data mux
  // --------------------------------------------------------------------------
  logic [31:0] rdata_mux;

  always_comb begin
    rdata_mux = '0;
    case (ar_addr_lat)
      REG_CONTROL:      rdata_mux = ctrl_reg;
      REG_STATUS:       rdata_mux = {27'b0, reg_status_i};
      REG_SRC_ADDR_LO:  rdata_mux = src_addr_lo_reg;
      REG_SRC_ADDR_HI:  rdata_mux = src_addr_hi_reg;
      REG_LENGTH:        rdata_mux = length_reg;
      REG_EXPECTED_CRC:  rdata_mux = expected_reg;
      REG_COMPUTED_CRC:  rdata_mux = reg_computed_i;
      REG_IRQ_ENABLE:    rdata_mux = irq_enable_reg;
      REG_IRQ_STATUS:    rdata_mux = {31'b0, reg_irq_status_i};
      default:           rdata_mux = 32'hDEAD_BEEF; // debug pattern for invalid addr
    endcase
  end

  // --------------------------------------------------------------------------
  // Read response (R channel) — respond one cycle after AR accepted
  // --------------------------------------------------------------------------
  logic        rvalid_r;
  logic [31:0] rdata_r;
  logic [1:0]  rresp_r;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rvalid_r <= 1'b0;
      rdata_r  <= '0;
      rresp_r  <= AXI_RESP_OKAY;
    end else begin
      if (ar_pending && !rvalid_r) begin
        rvalid_r <= 1'b1;
        rdata_r  <= rdata_mux;
        rresp_r  <= rd_addr_ok ? AXI_RESP_OKAY : AXI_RESP_SLVERR;
      end else if (rvalid_r && s_axi_rready) begin
        rvalid_r <= 1'b0;
      end
    end
  end

  assign s_axi_rvalid = rvalid_r;
  assign s_axi_rdata  = rdata_r;
  assign s_axi_rresp  = rresp_r;

  // --------------------------------------------------------------------------
  // Output assignments
  // --------------------------------------------------------------------------
  assign reg_start_o       = reg_start_r;
  assign reg_sw_reset_o    = reg_sw_reset_r;
  assign reg_irq_clear_o   = reg_irq_clear_r;
  assign reg_ie_o          = irq_enable_reg[IRQ_DONE_BIT];
  assign reg_src_addr_o    = src_addr_lo_reg;
  assign reg_src_addr_hi_o = src_addr_hi_reg;
  assign reg_length_o      = length_reg;
  assign reg_expected_o    = expected_reg;

endmodule : crc32_axi_lite_slave

`default_nettype wire
