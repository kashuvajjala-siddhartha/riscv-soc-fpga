// =============================================================================
// File        : tb_seven_segment_unit.sv
// Project     : WaveGuard SoC — IP Unit Verification
// Description : Standalone Unit Testbench for 7-Segment Display Controller
// =============================================================================

`timescale 1ns / 1ps

module tb_seven_segment_unit;

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

    logic [1:0]  hw_status_i;
    logic        hw_status_en;

    wire  [6:0]  seg_cathodes;
    wire  [3:0]  seg_anodes;
    wire         led_idle;
    wire         led_pass;
    wire         led_fail;

    localparam CLK_PERIOD = 10;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    seven_segment_ctrl #(
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
        .hw_status_i  (hw_status_i),
        .hw_status_en (hw_status_en),
        .seg_cathodes (seg_cathodes),
        .seg_anodes   (seg_anodes),
        .led_idle     (led_idle),
        .led_pass     (led_pass),
        .led_fail     (led_fail)
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

    integer errors = 0;

    initial begin
        rst_n = 0;
        hw_status_i = 2'b00;
        hw_status_en = 0;
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;

        $display("-------------------------------------------------------");
        $display("   STARTING 7-SEGMENT DISPLAY STANDALONE UNIT TEST     ");
        $display("-------------------------------------------------------");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: Reset / Default IDLE mode
        if (led_idle === 1'b1 && led_pass === 1'b0 && led_fail === 1'b0) begin
            $display("[PASS] Initial display state is IDLE (led_idle = 1).");
        end else begin
            $display("[FAIL] Initial state not IDLE.");
            errors = errors + 1;
        end

        // Test 2: Software Write PASS (0x01)
        write_reg(32'h00, 32'h0000_0001); // Mode PASS
        #(CLK_PERIOD * 2);
        if (led_pass === 1'b1 && led_idle === 1'b0) begin
            $display("[PASS] Software configuration: PASS state (led_pass = 1).");
        end else begin
            $display("[FAIL] Software PASS configuration failed.");
            errors = errors + 1;
        end

        // Test 3: Hardware override FAIL (0x02)
        hw_status_i  = 2'b10; // FAIL
        hw_status_en = 1'b1; // Override active
        #(CLK_PERIOD * 2);
        if (led_fail === 1'b1 && led_pass === 1'b0) begin
            $display("[PASS] Hardware override: FAIL state (led_fail = 1).");
        end else begin
            $display("[FAIL] Hardware FAIL override failed.");
            errors = errors + 1;
        end

        $display("-------------------------------------------------------");
        if (errors == 0) $display("   >>> ALL 7-SEGMENT UNIT TESTS PASSED (0 ERRORS) <<<");
        else             $display("   >>> 7-SEGMENT UNIT TEST FAILED WITH %0d ERRORS <<<", errors);
        $display("-------------------------------------------------------\n");
        $finish;
    end

endmodule
