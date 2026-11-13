// =============================================================================
// File        : tb_timer_std_unit.sv
// Project     : WaveGuard SoC — IP Unit Verification
// Description : Standalone Unit Testbench for Standard 32-bit Timer IP
// =============================================================================

`timescale 1ns / 1ps

module tb_timer_std_unit;

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

    wire         irq_timer;

    localparam CLK_PERIOD = 10;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    timer_std #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awprot (s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wstrb  (s_axi_wstrb),
        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),
        .s_axi_bresp  (s_axi_bresp),
        .s_axi_bvalid (s_axi_bvalid),
        .s_axi_bready (s_axi_bready),
        .s_axi_araddr (s_axi_araddr),
        .s_axi_arprot (s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata  (s_axi_rdata),
        .s_axi_rresp  (s_axi_rresp),
        .s_axi_rvalid (s_axi_rvalid),
        .s_axi_rready (s_axi_rready),
        .irq_timer    (irq_timer)
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
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;

        $display("-------------------------------------------------------");
        $display("   STARTING STANDARD TIMER STANDALONE UNIT TEST        ");
        $display("-------------------------------------------------------");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: Set Load threshold = 20 cycles, prescaler = 0, enable with IE
        write_reg(32'h10, 32'd20);        // LOAD = 20
        write_reg(32'h08, 32'd0);         // PRESCALE = 0
        write_reg(32'h00, 32'h0000_0007); // EN=1, AUTO_RELOAD=1, IE=1

        wait (irq_timer);
        $display("[PASS] Timer interrupt asserted upon reaching load value.");

        // Read Status
        read_reg(32'h04, rd);
        if (rd[0] === 1'b1) begin
            $display("[PASS] Timer STATUS register reflects interrupt pending.");
        end else begin
            $display("[FAIL] Timer STATUS pending flag not set.");
            errors = errors + 1;
        end

        // Clear interrupt via W1C
        write_reg(32'h04, 32'h0000_0001);
        #(CLK_PERIOD * 2);
        if (irq_timer === 1'b0) begin
            $display("[PASS] Timer interrupt successfully cleared.");
        end else begin
            $display("[FAIL] Timer interrupt not cleared.");
            errors = errors + 1;
        end

        $display("-------------------------------------------------------");
        if (errors == 0) $display("   >>> ALL TIMER UNIT TESTS PASSED (0 ERRORS) <<<");
        else             $display("   >>> TIMER UNIT TEST FAILED WITH %0d ERRORS <<<", errors);
        $display("-------------------------------------------------------\n");
        $finish;
    end

endmodule
