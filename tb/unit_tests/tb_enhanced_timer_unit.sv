// =============================================================================
// File        : tb_enhanced_timer_unit.sv
// Project     : WaveGuard SoC — IP Unit Verification
// Description : Standalone Unit Testbench for Enhanced Timer with Hardware
//               Watchdog & DMA/CRC Execution Profiler.
// =============================================================================

`timescale 1ns / 1ps

module tb_enhanced_timer_unit;

    logic        clk;
    logic        rst_n;

    logic [31:0] s_axi_awaddr;
    logic [2:0]  s_axi_awprot;
    logic        s_axi_awvalid;
    wire         s_axi_awready;

    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    wire         s_axi_wready;

    wire  [1:0]  s_axi_bresp;
    wire         s_axi_bvalid;
    logic        s_axi_bready;

    logic [31:0] s_axi_araddr;
    logic [2:0]  s_axi_arprot;
    logic        s_axi_arvalid;
    wire         s_axi_arready;

    wire  [31:0] s_axi_rdata;
    wire  [1:0]  s_axi_rresp;
    wire         s_axi_rvalid;
    logic        s_axi_rready;

    logic        dma_active;
    logic        dma_done;
    logic        crc_busy;
    logic        crc_done;

    wire         irq_timer;

    localparam CLK_PERIOD = 10;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    enhanced_timer #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dut (
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
        .dma_active       (dma_active),
        .dma_done         (dma_done),
        .crc_busy         (crc_busy),
        .crc_done         (crc_done),
        .irq_timer        (irq_timer)
    );

    task automatic write_reg(input [31:0] addr, input [31:0] data);
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        fork
            begin
                wait (s_axi_awready);
                @(posedge clk);
                s_axi_awvalid <= 1'b0;
            end
            begin
                wait (s_axi_wready);
                @(posedge clk);
                s_axi_wvalid <= 1'b0;
            end
        join

        wait (s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    task automatic read_reg(input [31:0] addr, output [31:0] data);
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;

        wait (s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 1'b0;

        wait (s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    logic [31:0] rd;
    integer errors = 0;

    initial begin
        rst_n = 0;
        dma_active = 0; dma_done = 0;
        crc_busy = 0; crc_done = 0;
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;

        $display("-------------------------------------------------------");
        $display("   STARTING ENHANCED TIMER STANDALONE UNIT TEST       ");
        $display("-------------------------------------------------------");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: Timer Enable & Compare Match
        write_reg(32'h10, 32'd15);        // MATCH = 15
        write_reg(32'h08, 32'd0);         // PRESCALER = 0
        write_reg(32'h00, 32'h0000_0007); // EN=1, AUTO_RELOAD=1, IE_MATCH=1

        wait (irq_timer);
        $display("[PASS] Enhanced Timer match interrupt asserted.");

        // Clear interrupt
        write_reg(32'h04, 32'h0000_0001); // W1C
        #(CLK_PERIOD * 2);

        // Test 2: DMA Profiling & Watchdog Timeout
        $display("[TIMER] Testing DMA execution profiling & Watchdog limit...");
        write_reg(32'h14, 32'd10);        // DMA_WD_LIMIT = 10 cycles
        write_reg(32'h00, 32'h0000_0008); // IE_DMA_WD = 1

        dma_active = 1'b1;
        #(CLK_PERIOD * 12);
        dma_active = 1'b0;
        dma_done = 1'b1;
        #(CLK_PERIOD * 2);
        dma_done = 1'b0;

        read_reg(32'h1C, rd); // DMA_ACTIVE_CYCLES
        $display("Profiled DMA Active Cycles: %0d (Expected: >= 12)", rd);
        if (rd >= 32'd12) begin
            $display("[PASS] DMA active cycle profiling verified.");
        end else begin
            $display("[FAIL] DMA profiling cycle count mismatch.");
            errors = errors + 1;
        end

        if (irq_timer === 1'b1) begin
            $display("[PASS] DMA Watchdog timeout triggered successfully (cycles > limit).");
        end else begin
            $display("[FAIL] DMA Watchdog timeout did not trigger.");
            errors = errors + 1;
        end

        $display("-------------------------------------------------------");
        if (errors == 0) $display("   >>> ALL ENHANCED TIMER UNIT TESTS PASSED (0 ERRORS) <<<");
        else             $display("   >>> ENHANCED TIMER UNIT TEST FAILED WITH %0d ERRORS <<<", errors);
        $display("-------------------------------------------------------\n");
        $finish;
    end

endmodule
