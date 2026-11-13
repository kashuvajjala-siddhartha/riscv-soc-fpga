// =============================================================================
// File        : tb_dma_uart_to_mem.sv
// Project     : DMA IP — VeeR EL2 SoC Honours Project
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : Self-checking testbench for dma_uart_to_mem Stage 1.
//
//   Includes:
//   - AXI4-Lite master driver (write/read register helpers)
//   - UART byte-stream driver with optional backpressure
//   - AXI4 write-slave memory model (256 bytes, captures WDATA/WSTRB/WADDR)
//   - Per-test memory-content, WSTRB, byte-count, and status checks
//
//   Test suite:
//   T01  1-byte transfer    (partial word, WSTRB=0x01)
//   T02  5-byte transfer    (partial word, WSTRB=0x1F)
//   T03  7-byte transfer    (partial word, WSTRB=0x7F)
//   T04  8-byte transfer    (exactly one full word, WSTRB=0xFF)
//   T05  9-byte transfer    (one full + one partial, WSTRB=[FF,01])
//   T06  16-byte transfer   (two full words)
//   T07  32-byte transfer   (four full words)
//   T08  UART backpressure  (FIFO fills; DMA must stall correctly)
//   T09  AXI AW/W backpressure (awready/wready delayed)
//   T10  AXI B-channel delay (bvalid delayed by many cycles)
//   T11  AXI SLVERR response → ERROR status, irq
//   T12  Misaligned DST_ADDR → ERROR on START
//   T13  Zero-length transfer → ERROR on START
//   T14  IRQ enable/clear
//   T15  Back-to-back transfers (no reset between T04 and a second 8-byte run)
// =============================================================================

`timescale 1ns / 1ps

module tb_dma_uart_to_mem;

    import dma_pkg::*;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam int ADDR_W     = 32;
    localparam int FIFO_DEPTH = 16;
    localparam int MEM_SIZE   = 512;   // bytes of simulated AXI memory
    localparam int CLK_PERIOD = 10;    // ns

    // =========================================================================
    // Clock and reset
    // =========================================================================
    logic clk  = 1'b0;
    logic rst_n;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // DUT signals
    // =========================================================================
    // AXI4-Lite
    logic [ADDR_W-1:0] s_axil_awaddr;
    logic [2:0]        s_axil_awprot;
    logic              s_axil_awvalid;
    logic              s_axil_awready;
    logic [31:0]       s_axil_wdata;
    logic [3:0]        s_axil_wstrb;
    logic              s_axil_wvalid;
    logic              s_axil_wready;
    logic [1:0]        s_axil_bresp;
    logic              s_axil_bvalid;
    logic              s_axil_bready;
    logic [ADDR_W-1:0] s_axil_araddr;
    logic [2:0]        s_axil_arprot;
    logic              s_axil_arvalid;
    logic              s_axil_arready;
    logic [31:0]       s_axil_rdata;
    logic [1:0]        s_axil_rresp;
    logic              s_axil_rvalid;
    logic              s_axil_rready;

    // UART
    logic [7:0]        uart_rx_data;
    logic              uart_rx_valid;
    logic              uart_rx_ready;

    // AXI4 write master
    logic [ADDR_W-1:0] m_axi_awaddr;
    logic [7:0]        m_axi_awlen;
    logic [2:0]        m_axi_awsize;
    logic [1:0]        m_axi_awburst;
    logic              m_axi_awlock;
    logic [3:0]        m_axi_awcache;
    logic [2:0]        m_axi_awprot;
    logic [3:0]        m_axi_awqos;
    logic              m_axi_awvalid;
    logic              m_axi_awready;
    logic [63:0]       m_axi_wdata;
    logic [7:0]        m_axi_wstrb;
    logic              m_axi_wlast;
    logic              m_axi_wvalid;
    logic              m_axi_wready;
    logic [1:0]        m_axi_bresp;
    logic              m_axi_bvalid;
    logic              m_axi_bready;

    // Status
    logic dma_active, dma_done, dma_error, irq_o;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    dma_uart_to_mem #(
        .ADDR_W     (ADDR_W),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axil_awaddr  (s_axil_awaddr),
        .s_axil_awprot  (s_axil_awprot),
        .s_axil_awvalid (s_axil_awvalid),
        .s_axil_awready (s_axil_awready),
        .s_axil_wdata   (s_axil_wdata),
        .s_axil_wstrb   (s_axil_wstrb),
        .s_axil_wvalid  (s_axil_wvalid),
        .s_axil_wready  (s_axil_wready),
        .s_axil_bresp   (s_axil_bresp),
        .s_axil_bvalid  (s_axil_bvalid),
        .s_axil_bready  (s_axil_bready),
        .s_axil_araddr  (s_axil_araddr),
        .s_axil_arprot  (s_axil_arprot),
        .s_axil_arvalid (s_axil_arvalid),
        .s_axil_arready (s_axil_arready),
        .s_axil_rdata   (s_axil_rdata),
        .s_axil_rresp   (s_axil_rresp),
        .s_axil_rvalid  (s_axil_rvalid),
        .s_axil_rready  (s_axil_rready),
        .uart_rx_data   (uart_rx_data),
        .uart_rx_valid  (uart_rx_valid),
        .uart_rx_ready  (uart_rx_ready),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awsize   (m_axi_awsize),
        .m_axi_awburst  (m_axi_awburst),
        .m_axi_awlock   (m_axi_awlock),
        .m_axi_awcache  (m_axi_awcache),
        .m_axi_awprot   (m_axi_awprot),
        .m_axi_awqos    (m_axi_awqos),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),
        .dma_active     (dma_active),
        .dma_done       (dma_done),
        .dma_error      (dma_error),
        .irq_o          (irq_o)
    );

    // =========================================================================
    // AXI4 write-slave memory model
    // Accepts single-beat writes (AWLEN=0).
    // Records: address, data, strobe for each beat.
    // Optional: inject_error flag → respond SLVERR.
    // Optional: aw_delay / w_delay → stall awready/wready.
    // Optional: b_delay → stall bvalid.
    // =========================================================================
    logic [7:0]        mem_bytes [0:MEM_SIZE-1];   // byte-addressable
    logic [ADDR_W-1:0] last_wr_addr;
    logic [63:0]       last_wr_data;
    logic [7:0]        last_wr_strb;
    int                wr_beat_count;

    logic              inject_error;
    int                aw_delay;   // cycles to stall awready
    int                w_delay;    // cycles to stall wready
    int                b_delay;    // cycles to stall bvalid after AW+W done

    // AW state
    logic              aw_active;
    logic [ADDR_W-1:0] aw_addr_q;
    int                aw_delay_ctr;

    // W state
    logic              w_active;
    int                w_delay_ctr;
    logic [63:0]       w_data_q;
    logic [7:0]        w_strb_q;

    // B state
    logic              b_pend;
    int                b_delay_ctr;

    // Initialize
    initial begin
        for (int i = 0; i < MEM_SIZE; i++) mem_bytes[i] = 8'hFF;
        wr_beat_count = 0;
        inject_error  = 1'b0;
        aw_delay      = 0;
        w_delay       = 0;
        b_delay       = 0;
        aw_active     = 1'b0;
        w_active      = 1'b0;
        b_pend        = 1'b0;
        aw_delay_ctr  = 0;
        w_delay_ctr   = 0;
        b_delay_ctr   = 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_awready <= 1'b0;
            m_axi_wready  <= 1'b0;
            m_axi_bvalid  <= 1'b0;
            m_axi_bresp   <= 2'b00;
            aw_active     <= 1'b0;
            w_active      <= 1'b0;
            b_pend        <= 1'b0;
            aw_delay_ctr  <= 0;
            w_delay_ctr   <= 0;
            b_delay_ctr   <= 0;
        end else begin
            // ---- AW channel ----
            if (!aw_active && !b_pend) begin
                if (aw_delay_ctr < aw_delay) begin
                    m_axi_awready <= 1'b0;
                    aw_delay_ctr  <= aw_delay_ctr + 1;
                end else begin
                    m_axi_awready <= 1'b1;
                    aw_delay_ctr  <= 0;
                end
            end else begin
                m_axi_awready <= 1'b0;
            end

            if (m_axi_awvalid && m_axi_awready) begin
                aw_addr_q <= m_axi_awaddr;
                aw_active <= 1'b1;
                m_axi_awready <= 1'b0;
            end

            // ---- W channel ----
            if (!w_active && !b_pend) begin
                if (w_delay_ctr < w_delay) begin
                    m_axi_wready <= 1'b0;
                    w_delay_ctr  <= w_delay_ctr + 1;
                end else begin
                    m_axi_wready <= 1'b1;
                    w_delay_ctr  <= 0;
                end
            end else begin
                m_axi_wready <= 1'b0;
            end

            if (m_axi_wvalid && m_axi_wready) begin
                w_data_q <= m_axi_wdata;
                w_strb_q <= m_axi_wstrb;
                w_active <= 1'b1;
                m_axi_wready <= 1'b0;
            end

            // ---- Commit when both AW and W captured ----
            if (aw_active && w_active) begin
                // Write strobe bytes into memory
                for (int i = 0; i < 8; i++) begin
                    if (w_strb_q[i] && (int'(aw_addr_q) + i < MEM_SIZE))
                        mem_bytes[int'(aw_addr_q) + i] <= w_data_q[i*8 +: 8];
                end
                last_wr_addr  <= aw_addr_q;
                last_wr_data  <= w_data_q;
                last_wr_strb  <= w_strb_q;
                wr_beat_count <= wr_beat_count + 1;
                aw_active     <= 1'b0;
                w_active      <= 1'b0;
                b_pend        <= 1'b1;
                b_delay_ctr   <= 0;
            end

            // ---- B channel ----
            if (b_pend) begin
                if (b_delay_ctr < b_delay) begin
                    m_axi_bvalid <= 1'b0;
                    b_delay_ctr  <= b_delay_ctr + 1;
                end else begin
                    m_axi_bvalid <= 1'b1;
                    m_axi_bresp  <= inject_error ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
                end
            end

            if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bvalid <= 1'b0;
                b_pend       <= 1'b0;
                m_axi_awready <= 1'b0;
                m_axi_wready  <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Pass/fail counters
    // =========================================================================
    int pass_count = 0;
    int fail_count = 0;

    task automatic check32(input string name, input logic [31:0] got,
                           input logic [31:0] exp);
        if (got === exp) begin
            $display("  PASS : %s = 0x%08X", name, got);
            pass_count++;
        end else begin
            $display("  FAIL : %s — expected 0x%08X, got 0x%08X", name, exp, got);
            fail_count++;
        end
    endtask

    task automatic check8(input string name, input logic [7:0] got,
                          input logic [7:0] exp);
        if (got === exp) begin
            $display("  PASS : %s = 0x%02X", name, got);
            pass_count++;
        end else begin
            $display("  FAIL : %s — expected 0x%02X, got 0x%02X", name, exp, got);
            fail_count++;
        end
    endtask

    task automatic check1(input string name, input logic got, input logic exp);
        if (got === exp) begin
            $display("  PASS : %s = %b", name, got);
            pass_count++;
        end else begin
            $display("  FAIL : %s — expected %b, got %b", name, exp, got);
            fail_count++;
        end
    endtask

    // =========================================================================
    // AXI4-Lite helpers
    // =========================================================================
    task automatic axil_write(input logic [ADDR_W-1:0] addr,
                              input logic [31:0] data,
                              input logic [3:0]  strb = 4'hF);
        // Present AW and W simultaneously; wait for both accepts; wait for B
        @(negedge clk);
        s_axil_awaddr  = addr;
        s_axil_awprot  = 3'b000;
        s_axil_awvalid = 1'b1;
        s_axil_wdata   = data;
        s_axil_wstrb   = strb;
        s_axil_wvalid  = 1'b1;
        s_axil_bready  = 1'b1;

        fork
            begin
                @(posedge clk);
                while (!s_axil_awready) @(posedge clk);
                #1; s_axil_awvalid = 1'b0;
            end
            begin
                @(posedge clk);
                while (!s_axil_wready) @(posedge clk);
                #1; s_axil_wvalid = 1'b0;
            end
        join

        @(posedge clk);
        while (!s_axil_bvalid) @(posedge clk);
        #1; s_axil_bready = 1'b0;
        @(posedge clk);
    endtask

    task automatic axil_read(input  logic [ADDR_W-1:0] addr,
                             output logic [31:0]        data);
        @(negedge clk);
        s_axil_araddr  = addr;
        s_axil_arprot  = 3'b000;
        s_axil_arvalid = 1'b1;
        s_axil_rready  = 1'b1;
        @(posedge clk);
        while (!s_axil_arready) @(posedge clk);
        #1; s_axil_arvalid = 1'b0;
        @(posedge clk);
        while (!s_axil_rvalid) @(posedge clk);
        data = s_axil_rdata;
        #1; s_axil_rready = 1'b0;
        @(posedge clk);
    endtask

    // =========================================================================
    // DMA configuration helpers
    // =========================================================================
    localparam logic [ADDR_W-1:0] REG_CTRL   = 'h00;
    localparam logic [ADDR_W-1:0] REG_STATUS = 'h04;
    localparam logic [ADDR_W-1:0] REG_DST_LO = 'h08;
    localparam logic [ADDR_W-1:0] REG_DST_HI = 'h0C;
    localparam logic [ADDR_W-1:0] REG_LENGTH = 'h10;
    localparam logic [ADDR_W-1:0] REG_COUNT  = 'h14;

    task automatic dma_configure(input logic [31:0] dst,
                                 input logic [31:0] len);
        axil_write(REG_DST_LO, dst);
        axil_write(REG_LENGTH, len);
    endtask

    // Enable DMA and fire START pulse
    task automatic dma_start(input logic irq_en = 1'b0);
        axil_write(REG_CTRL, {29'h0, irq_en, 2'b11}); // [2]=IRQ_EN [1]=START [0]=ENABLE
    endtask

    // Wait for DONE or ERROR bit, with timeout
    task automatic dma_wait(output logic [31:0] status, input int timeout = 5000);
        int t;
        logic [31:0] s;
        logic done_flag;
        done_flag = 1'b0;
        status = 32'hDEAD;
        for (t = 0; t < timeout && !done_flag; t++) begin
            axil_read(REG_STATUS, s);
            if (s[1] || s[2]) begin
                status = s;
                done_flag = 1'b1;
            end
        end
        if (!done_flag) begin
            $display("  TIMEOUT waiting for DMA completion");
        end
    endtask

    // Send N UART bytes; each byte value = base + i
    task automatic send_uart(input int n_bytes, input logic [7:0] base = 8'h00,
                             input int gap_cycles = 0);
        for (int i = 0; i < n_bytes; i++) begin
            @(negedge clk);
            uart_rx_data  = base + 8'(i);
            uart_rx_valid = 1'b1;
            @(posedge clk);
            // wait for ready (backpressure)
            while (!uart_rx_ready) @(posedge clk);
            #1; uart_rx_valid = 1'b0;
            // Optional gap between bytes
            repeat(gap_cycles) @(posedge clk);
        end
    endtask

    // =========================================================================
    // Memory check helpers
    // =========================================================================
    // Check n_bytes starting at dst_addr against expected bytes (base+i)
    task automatic check_mem(input int n_bytes, input logic [31:0] dst_addr,
                             input logic [7:0] base, input string tname);
        logic [7:0] exp_byte, got_byte;
        for (int i = 0; i < n_bytes; i++) begin
            exp_byte = base + 8'(i);
            got_byte = mem_bytes[dst_addr + i];
            if (got_byte !== exp_byte) begin
                $display("  FAIL : %s mem[%0d]=0x%02X expected 0x%02X",
                         tname, dst_addr+i, got_byte, exp_byte);
                fail_count++;
            end
        end
        // All bytes matched if no FAILs above
        begin
            logic all_ok;
            all_ok = 1'b1;
            for (int i = 0; i < n_bytes; i++) begin
                if (mem_bytes[dst_addr+i] !== (base + 8'(i))) all_ok = 1'b0;
            end
            if (all_ok) begin
                $display("  PASS : %s memory contents correct (%0d bytes)", tname, n_bytes);
                pass_count++;
            end
        end
    endtask

    // Reset memory to 0xFF
    task automatic mem_reset();
        for (int i = 0; i < MEM_SIZE; i++) mem_bytes[i] = 8'hFF;
        wr_beat_count = 0;
        inject_error  = 1'b0;
        aw_delay      = 0;
        w_delay       = 0;
        b_delay       = 0;
    endtask

    // Full DUT reset
    task automatic do_reset();
        @(negedge clk);
        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        #1; rst_n = 1'b1;
        @(posedge clk);
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        // Initialise all driven signals
        rst_n          = 1'b0;
        s_axil_awaddr  = '0;
        s_axil_awprot  = '0;
        s_axil_awvalid = 1'b0;
        s_axil_wdata   = '0;
        s_axil_wstrb   = 4'hF;
        s_axil_wvalid  = 1'b0;
        s_axil_bready  = 1'b0;
        s_axil_araddr  = '0;
        s_axil_arprot  = '0;
        s_axil_arvalid = 1'b0;
        s_axil_rready  = 1'b0;
        uart_rx_data   = 8'h00;
        uart_rx_valid  = 1'b0;

        $display("========================================================");
        $display("TB_DMA_UART_TO_MEM — Stage 1 Testbench");
        $display("========================================================");

        repeat(4) @(posedge clk);
        #1; rst_n = 1'b1;
        @(posedge clk);

        // =====================================================================
        // T01: 1-byte transfer — DST=0x00, LEN=1, expect WSTRB=0x01
        // =====================================================================
        $display("\n--- T01: 1-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd1);
        fork
            dma_start();
            send_uart(1, 8'hAA);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T01 STATUS.DONE",   st & 32'h2, 32'h2);
            check32("T01 STATUS.ERROR",  st & 32'h4, 32'h0);
        end
        check8("T01 mem[0]", mem_bytes[0], 8'hAA);
        check8("T01 WSTRB",  last_wr_strb, 8'h01);
        begin
            logic [31:0] cnt;
            axil_read(REG_COUNT, cnt);
            check32("T01 COUNT", cnt, 32'd1);
        end
        do_reset();

        // =====================================================================
        // T02: 5-byte transfer — WSTRB=0x1F
        // =====================================================================
        $display("\n--- T02: 5-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd5);
        fork
            dma_start();
            send_uart(5, 8'h10);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T02 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T02 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(5, 0, 8'h10, "T02");
        check8("T02 WSTRB", last_wr_strb, 8'h1F);
        do_reset();

        // =====================================================================
        // T03: 7-byte transfer — WSTRB=0x7F
        // =====================================================================
        $display("\n--- T03: 7-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd7);
        fork
            dma_start();
            send_uart(7, 8'h20);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T03 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T03 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(7, 0, 8'h20, "T03");
        check8("T03 WSTRB", last_wr_strb, 8'h7F);
        do_reset();

        // =====================================================================
        // T04: 8-byte transfer — exactly one full word, WSTRB=0xFF
        // =====================================================================
        $display("\n--- T04: 8-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'h30);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T04 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T04 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(8, 0, 8'h30, "T04");
        check8("T04 WSTRB", last_wr_strb, 8'hFF);
        begin
            logic [31:0] cnt;
            axil_read(REG_COUNT, cnt);
            check32("T04 COUNT", cnt, 32'd8);
        end
        do_reset();

        // =====================================================================
        // T05: 9-byte transfer — one full + one partial (WSTRB=[FF,01])
        // =====================================================================
        $display("\n--- T05: 9-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd9);
        fork
            dma_start();
            send_uart(9, 8'h40);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T05 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T05 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(9, 0, 8'h40, "T05");
        check8("T05 last WSTRB", last_wr_strb, 8'h01);
        begin
            logic [31:0] cnt;
            axil_read(REG_COUNT, cnt);
            check32("T05 COUNT", cnt, 32'd9);
        end
        do_reset();

        // =====================================================================
        // T06: 16-byte transfer — two full words
        // =====================================================================
        $display("\n--- T06: 16-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000010, 32'd16);  // DST=0x10
        fork
            dma_start();
            send_uart(16, 8'h50);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T06 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T06 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(16, 32'h10, 8'h50, "T06");
        begin
            logic [31:0] cnt;
            axil_read(REG_COUNT, cnt);
            check32("T06 COUNT", cnt, 32'd16);
        end
        do_reset();

        // =====================================================================
        // T07: 32-byte transfer — four full words
        // =====================================================================
        $display("\n--- T07: 32-byte transfer ---");
        mem_reset();
        dma_configure(32'h00000020, 32'd32);
        fork
            dma_start();
            send_uart(32, 8'h60);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T07 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T07 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(32, 32'h20, 8'h60, "T07");
        begin
            logic [31:0] cnt;
            axil_read(REG_COUNT, cnt);
            check32("T07 COUNT", cnt, 32'd32);
        end
        do_reset();

        // =====================================================================
        // T08: UART backpressure — send with gaps to exercise FIFO flow control
        // =====================================================================
        $display("\n--- T08: UART backpressure ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'h70, 3); // 3-cycle gap between each byte
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T08 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T08 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(8, 0, 8'h70, "T08");
        do_reset();

        // =====================================================================
        // T09: AXI AW/W backpressure (delayed awready and wready)
        // =====================================================================
        $display("\n--- T09: AXI AW/W backpressure ---");
        mem_reset();
        aw_delay = 5;   // stall awready for 5 cycles
        w_delay  = 3;   // stall wready for 3 cycles
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'h80);
        join
        begin
            logic [31:0] st;
            dma_wait(st, 2000);
            check32("T09 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T09 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(8, 0, 8'h80, "T09");
        aw_delay = 0; w_delay = 0;
        do_reset();

        // =====================================================================
        // T10: AXI B-channel delay (bvalid delayed by 20 cycles)
        // =====================================================================
        $display("\n--- T10: AXI B-channel delay ---");
        mem_reset();
        b_delay = 20;
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'h90);
        join
        begin
            logic [31:0] st;
            dma_wait(st, 2000);
            check32("T10 STATUS.DONE",  st & 32'h2, 32'h2);
            check32("T10 STATUS.ERROR", st & 32'h4, 32'h0);
        end
        check_mem(8, 0, 8'h90, "T10");
        b_delay = 0;
        do_reset();

        // =====================================================================
        // T11: AXI SLVERR → ERROR status + IRQ
        // =====================================================================
        $display("\n--- T11: AXI SLVERR response ---");
        mem_reset();
        inject_error = 1'b1;
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start(1'b1);  // IRQ enabled
            send_uart(8, 8'hA0);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T11 STATUS.ERROR", st & 32'h4, 32'h4);
            check32("T11 STATUS.DONE",  st & 32'h2, 32'h0);
        end
        check1("T11 irq_o asserted", irq_o, 1'b1);
        // Clear error via STATUS W1C
        axil_write(REG_STATUS, 32'h4);
        @(posedge clk); @(posedge clk);
        check1("T11 irq_o cleared", irq_o, 1'b0);
        inject_error = 1'b0;
        do_reset();

        // =====================================================================
        // T12: Misaligned DST_ADDR → ERROR on START (no AXI transaction)
        // =====================================================================
        $display("\n--- T12: Misaligned DST_ADDR ---");
        mem_reset();
        dma_configure(32'h00000003, 32'd8);  // address not 8-byte aligned
        dma_start();
        @(posedge clk); @(posedge clk); @(posedge clk);
        begin
            logic [31:0] st;
            axil_read(REG_STATUS, st);
            check32("T12 STATUS.ERROR", st & 32'h4, 32'h4);
            check32("T12 STATUS.DONE",  st & 32'h2, 32'h0);
        end
        check32("T12 no AXI beats", wr_beat_count, 32'd0);
        do_reset();

        // =====================================================================
        // T13: Zero-length transfer → ERROR on START
        // =====================================================================
        $display("\n--- T13: Zero-length transfer ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd0);
        dma_start();
        @(posedge clk); @(posedge clk); @(posedge clk);
        begin
            logic [31:0] st;
            axil_read(REG_STATUS, st);
            check32("T13 STATUS.ERROR", st & 32'h4, 32'h4);
            check32("T13 STATUS.DONE",  st & 32'h2, 32'h0);
        end
        do_reset();

        // =====================================================================
        // T14: IRQ enable/disable and W1C
        // =====================================================================
        $display("\n--- T14: IRQ enable/clear ---");
        mem_reset();
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start(1'b1);  // IRQ enabled
            send_uart(8, 8'hB0);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T14 STATUS.DONE", st & 32'h2, 32'h2);
        end
        check1("T14 irq_o asserted", irq_o, 1'b1);
        // Clear DONE via W1C
        axil_write(REG_STATUS, 32'h2);
        @(posedge clk); @(posedge clk);
        check1("T14 irq_o cleared", irq_o, 1'b0);
        // Disable IRQ and verify no reassertion
        axil_write(REG_CTRL, 32'h1);  // ENABLE only, no IRQ_ENABLE
        @(posedge clk);
        check1("T14 irq_o masked", irq_o, 1'b0);
        do_reset();

        // =====================================================================
        // T15: Back-to-back transfers (no system reset between runs)
        // =====================================================================
        $display("\n--- T15: Back-to-back transfers ---");
        mem_reset();
        // Run 1
        dma_configure(32'h00000000, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'hC0);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T15 Run1 STATUS.DONE", st & 32'h2, 32'h2);
        end
        check_mem(8, 0, 8'hC0, "T15-Run1");

        // Clear DONE flag so DMA accepts next START
        axil_write(REG_STATUS, 32'h2);
        repeat(4) @(posedge clk);

        // Run 2: different destination and data
        dma_configure(32'h00000010, 32'd8);
        fork
            dma_start();
            send_uart(8, 8'hD0);
        join
        begin
            logic [31:0] st;
            dma_wait(st);
            check32("T15 Run2 STATUS.DONE", st & 32'h2, 32'h2);
        end
        check_mem(8, 32'h10, 8'hD0, "T15-Run2");
        // Verify first region untouched
        check_mem(8, 0, 8'hC0, "T15-Run1-preserved");

        do_reset();

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n========================================================");
        $display("SUMMARY: %0d tests PASSED, %0d tests FAILED",
                 pass_count, fail_count);
        $display("========================================================");

        if (fail_count != 0)
            $fatal(1, "TB_DMA_UART_TO_MEM: %0d test(s) FAILED", fail_count);
        else
            $display("TB_DMA_UART_TO_MEM: ALL TESTS PASSED");

        $finish;
    end

    // Watchdog
    initial begin
        #2000000;
        $fatal(1, "TIMEOUT: simulation exceeded 2 ms");
    end

endmodule : tb_dma_uart_to_mem
