
`timescale 1ns/1ps

module soc_verification_top;

  import uvm_pkg::*;
  import crc32_pkg::*;
  import soc_verification_pkg::*;

  logic clk;

  soc_crc_if crc_if(clk);

  // 100 MHz clock
  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk;
  end

  // Reset: five clock cycles
  initial begin
    crc_if.rst_n = 1'b0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    crc_if.rst_n = 1'b1;
  end

  // CRC DUT
  crc32_top dut (
    .clk(clk),
    .rst_n(crc_if.rst_n),

    .s_axi_awaddr(crc_if.s_axi_awaddr),
    .s_axi_awprot(crc_if.s_axi_awprot),
    .s_axi_awvalid(crc_if.s_axi_awvalid),
    .s_axi_awready(crc_if.s_axi_awready),

    .s_axi_wdata(crc_if.s_axi_wdata),
    .s_axi_wstrb(crc_if.s_axi_wstrb),
    .s_axi_wvalid(crc_if.s_axi_wvalid),
    .s_axi_wready(crc_if.s_axi_wready),

    .s_axi_bresp(crc_if.s_axi_bresp),
    .s_axi_bvalid(crc_if.s_axi_bvalid),
    .s_axi_bready(crc_if.s_axi_bready),

    .s_axi_araddr(crc_if.s_axi_araddr),
    .s_axi_arprot(crc_if.s_axi_arprot),
    .s_axi_arvalid(crc_if.s_axi_arvalid),
    .s_axi_arready(crc_if.s_axi_arready),

    .s_axi_rdata(crc_if.s_axi_rdata),
    .s_axi_rresp(crc_if.s_axi_rresp),
    .s_axi_rvalid(crc_if.s_axi_rvalid),
    .s_axi_rready(crc_if.s_axi_rready),

    .m_axi_arid(crc_if.m_axi_arid),
    .m_axi_araddr(crc_if.m_axi_araddr),
    .m_axi_arlen(crc_if.m_axi_arlen),
    .m_axi_arsize(crc_if.m_axi_arsize),
    .m_axi_arburst(crc_if.m_axi_arburst),
    .m_axi_arlock(crc_if.m_axi_arlock),
    .m_axi_arcache(crc_if.m_axi_arcache),
    .m_axi_arprot(crc_if.m_axi_arprot),
    .m_axi_arqos(crc_if.m_axi_arqos),
    .m_axi_arvalid(crc_if.m_axi_arvalid),
    .m_axi_arready(crc_if.m_axi_arready),

    .m_axi_rid(crc_if.m_axi_rid),
    .m_axi_rdata(crc_if.m_axi_rdata),
    .m_axi_rresp(crc_if.m_axi_rresp),
    .m_axi_rlast(crc_if.m_axi_rlast),
    .m_axi_rvalid(crc_if.m_axi_rvalid),
    .m_axi_rready(crc_if.m_axi_rready),

    .irq_o(crc_if.irq_o)
  );

  // Configure interface and start UVM at time zero
  initial begin
    uvm_config_db#(virtual soc_crc_if)::set(
      null, "*", "vif", crc_if
    );

    run_test("crc_base_test");
  end

   // FSDB waveform dumping
initial begin
  $fsdbDumpfile("verification/crc_uvm.fsdb");
  $fsdbDumpvars(0, soc_verification_top, "+all");
end
endmodule

