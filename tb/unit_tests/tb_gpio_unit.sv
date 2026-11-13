// =============================================================================
// File        : tb_gpio_unit.sv
// Project     : WaveGuard SoC — IP Unit Verification
// Description : Standalone Unit Testbench for 32-bit GPIO Controller
// =============================================================================

`timescale 1ns / 1ps

module tb_gpio_unit;

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

    logic [31:0] gpio_i;
    wire  [31:0] gpio_o;
    wire  [31:0] gpio_oe;
    wire         irq_gpio;

    localparam CLK_PERIOD = 10;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    gpio_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .NUM_GPIOS (32)
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
        .gpio_i       (gpio_i),
        .gpio_o       (gpio_o),
        .gpio_oe      (gpio_oe),
        .irq_gpio     (irq_gpio)
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
        gpio_i = 32'h0;
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;

        $display("-------------------------------------------------------");
        $display("   STARTING GPIO IP STANDALONE UNIT TEST               ");
        $display("-------------------------------------------------------");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: Direction and Output driving
        write_reg(32'h08, 32'h0000_FFFF); // Lower 16 bits = Output
        write_reg(32'h04, 32'h0000_1234); // DATA_OUT = 0x1234
        #(CLK_PERIOD * 2);
        if (gpio_o[15:0] === 16'h1234 && gpio_oe[15:0] === 16'hFFFF) begin
            $display("[PASS] GPIO Direction & Output driving verified.");
        end else begin
            $display("[FAIL] GPIO Output mismatch: gpio_o=0x%h, gpio_oe=0x%h", gpio_o, gpio_oe);
            errors = errors + 1;
        end

        // Test 2: Input reading
        gpio_i[31:16] = 16'hABCD;
        #(CLK_PERIOD * 5);
        read_reg(32'h00, rd); // DATA_IN
        if (rd[31:16] === 16'hABCD) begin
            $display("[PASS] GPIO Input sampling verified.");
        end else begin
            $display("[FAIL] GPIO Input mismatch: 0x%h", rd);
            errors = errors + 1;
        end

        // Test 3: Interrupt Generation (Rising edge)
        write_reg(32'h0C, 32'h0001_0000); // INT_EN bit 16
        write_reg(32'h14, 32'h0000_0000); // INT_TYPE = edge
        gpio_i[16] = 1'b0;
        #(CLK_PERIOD * 3);
        gpio_i[16] = 1'b1; // Rising edge
        #(CLK_PERIOD * 5);
        if (irq_gpio === 1'b1) begin
            $display("[PASS] GPIO Interrupt asserted on rising edge.");
        end else begin
            $display("[FAIL] GPIO Interrupt not asserted.");
            errors = errors + 1;
        end

        // Clear interrupt
        write_reg(32'h10, 32'h0001_0000); // W1C
        #(CLK_PERIOD * 3);
        if (irq_gpio === 1'b0) begin
            $display("[PASS] GPIO Interrupt successfully cleared.");
        end else begin
            $display("[FAIL] GPIO Interrupt not cleared.");
            errors = errors + 1;
        end

        $display("-------------------------------------------------------");
        if (errors == 0) $display("   >>> ALL GPIO UNIT TESTS PASSED (0 ERRORS) <<<");
        else             $display("   >>> GPIO UNIT TEST FAILED WITH %0d ERRORS <<<", errors);
        $display("-------------------------------------------------------\n");
        $finish;
    end

endmodule
