// =============================================================================
// File        : tb_crc32_soc.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : End-to-end self-checking testbench for crc32_top.
//
//   Instantiates crc32_top with:
//   - An AXI4-Lite master BFM driving the slave interface (processor role)
//   - A behavioural AXI4 slave memory responding to the read master
//
//   The memory is pre-loaded with the ASCII string "123456789" at address 0
//   plus a variety of other test patterns.
//
//   Tests performed:
//   T01 Check vector "123456789" — PASS (correct expected CRC)
//   T02 Check vector "123456789" — FAIL (wrong expected CRC)
//   T03 Interrupt generation and clearing
//   T04 Interrupt masking (IE=0, no interrupt)
//   T05 Status BUSY while running, DONE after
//   T06 Zero-length transfer
//   T07 Long transfer (64 bytes)
//   T08 SW_RESET clears status
//   T09 Error response handling
//   T10 Second run after first completes
// =============================================================================

`timescale 1ns / 1ps

module tb_crc32_soc;

  import crc32_pkg::*;

  // --------------------------------------------------------------------------
  // Parameters
  // --------------------------------------------------------------------------
  localparam int AXIL_AW   = 32;
  localparam int AXIM_AW   = 32;
  localparam int AXIM_IDW  = 8;
  localparam int MAX_BURST = 4;
  localparam int MEM_SIZE  = 256;

  // --------------------------------------------------------------------------
  // Clock and reset
  // --------------------------------------------------------------------------
  logic clk  = 0;
  logic rst_n;

  always #5 clk = ~clk;

  // --------------------------------------------------------------------------
  // AXI4-Lite slave (to DUT) signals
  // --------------------------------------------------------------------------
  logic [31:0] s_axi_awaddr,  s_axi_araddr;
  logic [2:0]  s_axi_awprot,  s_axi_arprot;
  logic        s_axi_awvalid, s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic [3:0]  s_axi_wstrb;
  logic        s_axi_wvalid,  s_axi_wready;
  logic [1:0]  s_axi_bresp;
  logic        s_axi_bvalid,  s_axi_bready;
  logic        s_axi_arvalid, s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0]  s_axi_rresp;
  logic        s_axi_rvalid,  s_axi_rready;

  // --------------------------------------------------------------------------
  // AXI4 read master (from DUT) signals
  // --------------------------------------------------------------------------
  logic [AXIM_IDW-1:0]  m_axi_arid;
  logic [AXIM_AW-1:0]   m_axi_araddr;
  logic [7:0]           m_axi_arlen;
  logic [2:0]           m_axi_arsize;
  logic [1:0]           m_axi_arburst;
  logic                 m_axi_arlock;
  logic [3:0]           m_axi_arcache;
  logic [2:0]           m_axi_arprot;
  logic [3:0]           m_axi_arqos;
  logic                 m_axi_arvalid, m_axi_arready;
  logic [AXIM_IDW-1:0]  m_axi_rid;
  logic [63:0]          m_axi_rdata;
  logic [1:0]           m_axi_rresp;
  logic                 m_axi_rlast;
  logic                 m_axi_rvalid, m_axi_rready;

  // --------------------------------------------------------------------------
  // IRQ
  // --------------------------------------------------------------------------
  logic irq_o;

  // --------------------------------------------------------------------------
  // DUT instantiation
  // --------------------------------------------------------------------------
  crc32_top #(
    .AXIL_ADDR_WIDTH (AXIL_AW),
    .AXIM_ADDR_WIDTH (AXIM_AW),
    .AXIM_ID_WIDTH   (AXIM_IDW),
    .MAX_BURST_LEN   (MAX_BURST)
  ) u_dut (
    .clk           (clk),
    .rst_n         (rst_n),

    .s_axi_awaddr  (s_axi_awaddr),  .s_axi_awprot  (s_axi_awprot),
    .s_axi_awvalid (s_axi_awvalid), .s_axi_awready (s_axi_awready),
    .s_axi_wdata   (s_axi_wdata),   .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),  .s_axi_wready  (s_axi_wready),
    .s_axi_bresp   (s_axi_bresp),   .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    .s_axi_araddr  (s_axi_araddr),  .s_axi_arprot  (s_axi_arprot),
    .s_axi_arvalid (s_axi_arvalid), .s_axi_arready (s_axi_arready),
    .s_axi_rdata   (s_axi_rdata),   .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),  .s_axi_rready  (s_axi_rready),

    .m_axi_arid    (m_axi_arid),    .m_axi_araddr  (m_axi_araddr),
    .m_axi_arlen   (m_axi_arlen),   .m_axi_arsize  (m_axi_arsize),
    .m_axi_arburst (m_axi_arburst), .m_axi_arlock  (m_axi_arlock),
    .m_axi_arcache (m_axi_arcache), .m_axi_arprot  (m_axi_arprot),
    .m_axi_arqos   (m_axi_arqos),   .m_axi_arvalid (m_axi_arvalid),
    .m_axi_arready (m_axi_arready),
    .m_axi_rid     (m_axi_rid),     .m_axi_rdata   (m_axi_rdata),
    .m_axi_rresp   (m_axi_rresp),   .m_axi_rlast   (m_axi_rlast),
    .m_axi_rvalid  (m_axi_rvalid),  .m_axi_rready  (m_axi_rready),

    .irq_o         (irq_o)
  );

  // --------------------------------------------------------------------------
  // Behavioural AXI4 slave memory
  // --------------------------------------------------------------------------
  logic [7:0] mem [0:MEM_SIZE-1];

  // Initialise memory: first 9 bytes = "123456789", rest = sequential
  initial begin
    mem[0] = 8'h31; mem[1] = 8'h32; mem[2] = 8'h33;
    mem[3] = 8'h34; mem[4] = 8'h35; mem[5] = 8'h36;
    mem[6] = 8'h37; mem[7] = 8'h38; mem[8] = 8'h39;
    for (int i = 9; i < MEM_SIZE; i++)
      mem[i] = 8'(i);
  end

  // Error injection control
  logic inject_err = 1'b0;

  // AR latch
  logic [AXIM_AW-1:0] baddr;
  logic [7:0]         blen;
  logic               bpend;  // no inline init — reset in always_ff

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_axi_arready <= 1'b0;
      m_axi_rvalid  <= 1'b0;
      m_axi_rlast   <= 1'b0;
      m_axi_rid     <= '0;
      bpend         <= 1'b0;
    end else begin
      if (!bpend) begin
        m_axi_arready <= 1'b1;
        if (m_axi_arvalid && m_axi_arready) begin
          baddr         <= m_axi_araddr;
          blen          <= m_axi_arlen;
          bpend         <= 1'b1;
          m_axi_arready <= 1'b0;
        end
      end
      if (bpend) begin
        m_axi_rvalid <= 1'b1;
        for (int i = 0; i < 8; i++) begin
          m_axi_rdata[i*8 +: 8] <= ((baddr + i) < MEM_SIZE) ? mem[baddr + i] : 8'h00;
        end
        m_axi_rresp <= inject_err ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
        m_axi_rlast <= (blen == 8'h0);
        if (m_axi_rvalid && m_axi_rready) begin
          if (blen == 8'h0) begin
            m_axi_rvalid  <= 1'b0;
            bpend         <= 1'b0;
            m_axi_arready <= 1'b1;
          end else begin
            baddr <= baddr + 32'd8;
            blen  <= blen - 8'd1;
            m_axi_rlast <= (blen == 8'h1);
          end
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // AXI4-Lite BFM tasks
  // --------------------------------------------------------------------------
  task automatic bus_reset();
    s_axi_awvalid = 0; s_axi_awaddr = 0; s_axi_awprot = 0;
    s_axi_wvalid  = 0; s_axi_wdata  = 0; s_axi_wstrb  = 4'hF;
    s_axi_bready  = 1;
    s_axi_arvalid = 0; s_axi_araddr = 0; s_axi_arprot = 0;
    s_axi_rready  = 1;
  endtask

  task automatic write_reg(input logic [31:0] addr, input logic [31:0] data);
    logic [1:0] bresp;
    @(negedge clk);
    s_axi_awvalid = 1; s_axi_awaddr = addr;
    s_axi_wvalid  = 1; s_axi_wdata  = data; s_axi_wstrb = 4'hF;
    @(posedge clk);
    while (!s_axi_awready || !s_axi_wready) @(posedge clk);
    @(negedge clk); s_axi_awvalid = 0; s_axi_wvalid = 0;
    @(posedge clk);
    while (!s_axi_bvalid) @(posedge clk);
    @(posedge clk);
  endtask

  task automatic read_reg(input logic [31:0] addr, output logic [31:0] data);
    @(negedge clk);
    s_axi_arvalid = 1; s_axi_araddr = addr;
    @(posedge clk);
    while (!s_axi_arready) @(posedge clk);
    @(negedge clk); s_axi_arvalid = 0;
    @(posedge clk);
    while (!s_axi_rvalid) @(posedge clk);
    data = s_axi_rdata;
    @(posedge clk);
  endtask

  task automatic do_reset();
    @(negedge clk); rst_n = 0;
    repeat(4) @(posedge clk);
    #1; rst_n = 1;
    @(posedge clk);
  endtask

  // Start CRC calculation and wait for done
  task automatic run_crc(
    input  logic [31:0] src_addr,
    input  logic [31:0] length,
    input  logic [31:0] expected_crc,
    input  logic        irq_en,
    input  int          timeout_cycles,
    output logic [31:0] status_out,
    output logic [31:0] computed_out
  );
    // Program registers
    write_reg(32'h08, src_addr);     // SRC_ADDR_LO
    write_reg(32'h10, length);       // LENGTH
    write_reg(32'h14, expected_crc); // EXPECTED_CRC
    write_reg(32'h1C, {31'b0, irq_en}); // IRQ_ENABLE
    // Start
    write_reg(32'h00, 32'h00000001); // CONTROL.START

    // Poll STATUS until DONE or ERROR
    begin
      int t = 0;
      logic [31:0] st;
      st = 32'h0;
      while (!st[1] && !st[4] && t < timeout_cycles) begin
        @(posedge clk);
        read_reg(32'h04, st);
        t++;
      end
      status_out = st;
      if (t >= timeout_cycles)
        $display("WARN: run_crc TIMEOUT");
    end
    read_reg(32'h18, computed_out); // COMPUTED_CRC
  endtask

  // --------------------------------------------------------------------------
  // Pass/fail counters
  // --------------------------------------------------------------------------
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(
    input string      tname,
    input logic [31:0] actual,
    input logic [31:0] expected
  );
    if (actual === expected) begin
      $display("PASS : %s — 0x%08X", tname, actual);
      pass_count++;
    end else begin
      $display("FAIL : %s — expected 0x%08X, got 0x%08X", tname, expected, actual);
      fail_count++;
    end
  endtask

  task automatic check1(
    input string tname,
    input logic  actual,
    input logic  expected
  );
    if (actual === expected) begin
      $display("PASS : %s — %b", tname, actual);
      pass_count++;
    end else begin
      $display("FAIL : %s — expected %b, got %b", tname, expected, actual);
      fail_count++;
    end
  endtask

  // --------------------------------------------------------------------------
  // Main test sequence
  // --------------------------------------------------------------------------
  logic [31:0] status, computed;

  initial begin
    $display("============================================================");
    $display("TB_CRC32_SOC — End-to-End CRC-32 IP Testbench");
    $display("============================================================");

    bus_reset();
    do_reset();

    // ------------------------------------------------------------------
    // T01: "123456789" — correct expected CRC → PASS
    // ------------------------------------------------------------------
    $display("--- T01: check vector PASS ---");
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T01 STATUS.DONE",    {30'b0, status[1], 1'b0}, 32'h2);
    check("T01 STATUS.PASS",    {29'b0, status[2], 2'b0}, 32'h4);
    check("T01 STATUS.FAIL",    {28'b0, status[3], 3'b0}, 32'h0);
    check("T01 COMPUTED_CRC",   computed, 32'hCBF43926);

    do_reset();

    // ------------------------------------------------------------------
    // T02: "123456789" — wrong expected CRC → FAIL
    // ------------------------------------------------------------------
    $display("--- T02: check vector FAIL ---");
    run_crc(32'h0, 32'd9, 32'hDEADBEEF, 1'b0, 2000, status, computed);
    check("T02 STATUS.DONE",    {30'b0, status[1], 1'b0}, 32'h2);
    check("T02 STATUS.FAIL",    {28'b0, status[3], 3'b0}, 32'h8);
    check("T02 STATUS.PASS==0", {29'b0, status[2], 2'b0}, 32'h0);
    check("T02 COMPUTED_CRC",   computed, 32'hCBF43926);

    do_reset();

    // ------------------------------------------------------------------
    // T03: Interrupt generation
    // ------------------------------------------------------------------
    $display("--- T03: interrupt generation ---");
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b1, 2000, status, computed);
    check1("T03 irq_o asserted", irq_o, 1'b1);
    // Clear IRQ by writing 1 to IRQ_STATUS
    write_reg(32'h20, 32'h00000001);
    @(posedge clk); @(posedge clk);
    check1("T03 irq_o cleared", irq_o, 1'b0);

    do_reset();

    // ------------------------------------------------------------------
    // T04: Interrupt masking (IE=0, no interrupt expected)
    // ------------------------------------------------------------------
    $display("--- T04: interrupt masking ---");
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    @(posedge clk);
    check1("T04 irq_o masked (IE=0)", irq_o, 1'b0);

    do_reset();

    // ------------------------------------------------------------------
    // T05: Check BUSY while running (poll during operation)
    // ------------------------------------------------------------------
    $display("--- T05: BUSY/DONE status ---");
    begin
      logic [31:0] st_during;
      write_reg(32'h08, 32'h0);   // SRC_ADDR_LO
      write_reg(32'h10, 32'd9);   // LENGTH
      write_reg(32'h14, 32'hCBF43926);
      write_reg(32'h1C, 32'h0);
      write_reg(32'h00, 32'h1);   // START

      // Sample status one cycle later
      @(posedge clk);
      read_reg(32'h04, st_during);
      // BUSY should have been 1 or DONE already set (fast IP)
      // We accept either BUSY=1 or DONE=1 within a few cycles
      check1("T05 DONE or BUSY seen", st_during[1] | st_during[0], 1'b1);

      // Wait for done
      repeat(2000) @(posedge clk);
      read_reg(32'h04, st_during);
      check("T05 STATUS.DONE eventually", {30'b0, st_during[1], 1'b0}, 32'h2);
    end

    do_reset();

    // ------------------------------------------------------------------
    // T06: Zero-length transfer
    // ------------------------------------------------------------------
    $display("--- T06: zero-length transfer ---");
    run_crc(32'h0, 32'd0, 32'h00000000, 1'b0, 200, status, computed);
    check("T06 STATUS.DONE on zero-length", {30'b0, status[1], 1'b0}, 32'h2);

    do_reset();

    // ------------------------------------------------------------------
    // T07: Longer transfer — 32 bytes from memory address 0
    // (CRC computed by SW reference and stored as expected)
    // ------------------------------------------------------------------
    $display("--- T07: 32-byte transfer ---");
    begin
      // Compute expected CRC in simulation
      logic [31:0] crc32;
      logic        fb;
      crc32 = 32'hFFFFFFFF;
      for (int i = 0; i < 32; i++) begin
        for (int b = 0; b < 8; b++) begin
          fb   = crc32[0] ^ mem[i][b];
          crc32 = {1'b0, crc32[31:1]};
          if (fb) crc32 ^= 32'hEDB88320;
        end
      end
      crc32 ^= 32'hFFFFFFFF;

      run_crc(32'h0, 32'd32, crc32, 1'b0, 5000, status, computed);
      check("T07 COMPUTED matches reference", computed, crc32);
      check("T07 STATUS.PASS", {29'b0, status[2], 2'b0}, 32'h4);
    end

    do_reset();

    // ------------------------------------------------------------------
    // T08: SW_RESET clears status
    // ------------------------------------------------------------------
    $display("--- T08: SW_RESET clears status ---");
    // First run a calculation
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T08a DONE before reset", {30'b0, status[1], 1'b0}, 32'h2);
    // Issue SW_RESET
    write_reg(32'h00, 32'h00000004);  // CONTROL.RESET
    @(posedge clk); @(posedge clk);
    read_reg(32'h04, status);
    check("T08b STATUS cleared after SW_RESET", status[4:0], 32'h0);

    do_reset();

    // ------------------------------------------------------------------
    // T09: Error response handling
    // ------------------------------------------------------------------
    $display("--- T09: error response ---");
    inject_err = 1'b1;
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 500, status, computed);
    check("T09 STATUS.ERROR", {27'b0, status[4], 4'b0}, 32'h10);
    inject_err = 1'b0;

    do_reset();

    // ------------------------------------------------------------------
    // T10: Second run after first completes
    // ------------------------------------------------------------------
    $display("--- T10: second run ---");
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T10 First run PASS",    {29'b0, status[2], 2'b0}, 32'h4);
    // Immediately start again
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T10 Second run PASS",   {29'b0, status[2], 2'b0}, 32'h4);
    check("T10 COMPUTED same",     computed, 32'hCBF43926);

    do_reset();

    // ------------------------------------------------------------------
    // T11: Three consecutive transactions without any system reset
    //   - Run 1: "123456789" → expect PASS (correct CRC)
    //   - Run 2: "123456789" → expect PASS (correct CRC, same data)
    //   - Run 3: "123456789" → expect FAIL (wrong expected CRC)
    // No do_reset() between any of the three runs.
    // ------------------------------------------------------------------
    $display("--- T11: three consecutive runs, no reset between them ---");

    // Run 1: correct expected CRC → PASS
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T11 Run1 STATUS.DONE",    {30'b0, status[1], 1'b0}, 32'h2);
    check("T11 Run1 STATUS.PASS",    {29'b0, status[2], 2'b0}, 32'h4);
    check("T11 Run1 COMPUTED_CRC",   computed, 32'hCBF43926);

    // Run 2: correct expected CRC → PASS (no reset between Run 1 and Run 2)
    run_crc(32'h0, 32'd9, 32'hCBF43926, 1'b0, 2000, status, computed);
    check("T11 Run2 STATUS.DONE",    {30'b0, status[1], 1'b0}, 32'h2);
    check("T11 Run2 STATUS.PASS",    {29'b0, status[2], 2'b0}, 32'h4);
    check("T11 Run2 COMPUTED_CRC",   computed, 32'hCBF43926);

    // Run 3: wrong expected CRC → FAIL (no reset between Run 2 and Run 3)
    run_crc(32'h0, 32'd9, 32'hDEADBEEF, 1'b0, 2000, status, computed);
    check("T11 Run3 STATUS.DONE",    {30'b0, status[1], 1'b0}, 32'h2);
    check("T11 Run3 STATUS.FAIL",    {28'b0, status[3], 3'b0}, 32'h8);
    check("T11 Run3 COMPUTED_CRC",   computed, 32'hCBF43926);

    // ------------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------------
    $display("============================================================");
    $display("SUMMARY: %0d tests PASSED, %0d tests FAILED", pass_count, fail_count);
    $display("============================================================");

    if (fail_count != 0)
      $fatal(1, "TB_CRC32_SOC: %0d test(s) FAILED", fail_count);
    else
      $display("TB_CRC32_SOC: ALL TESTS PASSED");

    $finish;
  end

  // --------------------------------------------------------------------------
  // Timeout watchdog
  // --------------------------------------------------------------------------
  initial begin
    #5000000;
    $fatal(1, "TIMEOUT: simulation exceeded 5000000 ns");
  end

endmodule : tb_crc32_soc
