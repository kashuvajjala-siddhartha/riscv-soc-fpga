// =============================================================================
// File        : tb_uart_unit.sv
// Project     : WaveGuard SoC — IP Unit Verification
// Description : Standalone Unit Testbench for Full-Duplex UART Controller IP
// =============================================================================

`timescale 1ns / 1ps

module tb_uart_unit;

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

    logic        uart_rx;
    wire         uart_tx;

    wire  [7:0]  m_axis_tdata;
    wire         m_axis_tvalid;
    logic        m_axis_tready;

    wire         irq_uart;

    localparam CLK_PERIOD = 10;
    localparam CLKS_PER_BIT = 16;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    uart_top #(
        .ADDR_WIDTH  (32),
        .DATA_WIDTH  (32),
        .CLKS_PER_BIT(CLKS_PER_BIT)
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
        .uart_rx      (uart_rx),
        .uart_tx      (uart_tx),
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .irq_uart     (irq_uart)
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

    task automatic send_serial_byte(input [7:0] byte_val);
        integer b;
        uart_rx <= 1'b0; // Start
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (b = 0; b < 8; b = b + 1) begin
            uart_rx <= byte_val[b];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        uart_rx <= 1'b1; // Stop
        repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    logic [31:0] rd;
    integer errors = 0;

    initial begin
        rst_n = 0;
        uart_rx = 1'b1;
        m_axis_tready = 1'b1;
        s_axi_awvalid = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_arvalid = 0; s_axi_rready = 0;

        $display("-------------------------------------------------------");
        $display("   STARTING UART IP STANDALONE UNIT TEST               ");
        $display("-------------------------------------------------------");

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: External Serial Ingestion -> Streaming out to DMA
        $display("[UART] Injecting serial byte 0x4B ('K')...");
        fork
            begin
                wait (m_axis_tvalid);
                if (m_axis_tdata === 8'h4B) begin
                    $display("[PASS] Serial RX byte captured and streamed to DMA: 0x%02X", m_axis_tdata);
                end else begin
                    $display("[FAIL] Streaming data mismatch: 0x%02X", m_axis_tdata);
                    errors = errors + 1;
                end
            end
            begin
                send_serial_byte(8'h4B);
            end
        join

        // Test 2: Internal Loopback Mode (TX -> RX)
        $display("[UART] Testing Loopback CSR Mode...");
        write_reg(32'h0C, 32'h0000_0003); // LOOPBACK_EN=1, RX_IE=1
        write_reg(32'h00, 32'h0000_007E); // Transmit 0x7E
        #(CLK_PERIOD * CLKS_PER_BIT * 12);

        read_reg(32'h04, rd); // Read RX_DATA
        if (rd[7:0] === 8'h7E) begin
            $display("[PASS] UART Loopback received transmitted byte: 0x%02X", rd[7:0]);
        end else begin
            $display("[FAIL] UART Loopback mismatch: 0x%02X", rd[7:0]);
            errors = errors + 1;
        end

        $display("-------------------------------------------------------");
        if (errors == 0) $display("   >>> ALL UART UNIT TESTS PASSED (0 ERRORS) <<<");
        else             $display("   >>> UART UNIT TEST FAILED WITH %0d ERRORS <<<", errors);
        $display("-------------------------------------------------------\n");
        $finish;
    end

endmodule
