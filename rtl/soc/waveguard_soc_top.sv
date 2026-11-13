// =============================================================================
// File        : waveguard_soc_top.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : Complete System-on-Chip integrating:
//                 - RISC-V Processor Core Interface (VeeR-EL2 compatible)
//                 - Instruction Memory (IMEM) & Data Memory (DMEM)
//                 - 64-bit AXI4 Interconnect Fabric & AXI4-Lite Bridge
//                 - UART Controller (Full TX/RX + Streaming Link to DMA)
//                 - Standard Timer IP
//                 - 32-bit GPIO Controller
//                 - DMA Controller IP (64-bit Write Master)
//                 - CRC-32 Engine IP (64-bit Read Master)
//                 - Enhanced Timer IP (Hardware Watchdog & Profiler)
//                 - 7-Segment Display Controller (PASS/FAIL/IDLE)
//
// Complete SoC Memory Map:
//   0x0000_0000 - 0x0000_7FFF : Instruction Memory (IMEM - 32 KB)
//   0x0000_8000 - 0x0000_FFFF : Data Memory (DMEM - 32 KB)
//   0x8000_0000 - 0x8000_0FFF : DMA Controller
//   0x8000_1000 - 0x8000_1FFF : CRC-32 Engine
//   0x8000_2000 - 0x8000_2FFF : Enhanced Timer (Profiling & Watchdogs)
//   0x8000_3000 - 0x8000_3FFF : 7-Segment Display Controller
//   0x8000_4000 - 0x8000_4FFF : Full UART Controller
//   0x8000_5000 - 0x8000_5FFF : Standard Timer
//   0x8000_6000 - 0x8000_6FFF : 32-bit GPIO Controller
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module waveguard_soc_top #(
    parameter int AXI_ADDR_WIDTH   = 32,
    parameter int AXI_DATA_WIDTH   = 64,
    parameter int AXI_ID_WIDTH     = 8,
    parameter int UART_CLKS_PER_BIT= 16,
    parameter int NUM_GPIOS        = 32,
    parameter     INIT_HEX_FILE    = ""
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // UART Physical Interface
    input  wire                   uart_rx,
    output wire                   uart_tx,

    // GPIO External Pins
    input  wire [NUM_GPIOS-1:0]   gpio_i,
    output wire [NUM_GPIOS-1:0]   gpio_o,
    output wire [NUM_GPIOS-1:0]   gpio_oe,

    // 7-Segment Display & Diagnostic LEDs
    output wire [6:0]             seg_cathodes,
    output wire [3:0]             seg_anodes,
    output wire                   led_idle,
    output wire                   led_pass,
    output wire                   led_fail,

    // Processor Core AXI4 Master Interface (VeeR-EL2 IFU/LSU or BFM driver)
    input  wire [AXI_ID_WIDTH-1:0]   cpu_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0] cpu_axi_awaddr,
    input  wire [7:0]                cpu_axi_awlen,
    input  wire [2:0]                cpu_axi_awsize,
    input  wire [1:0]                cpu_axi_awburst,
    input  wire                      cpu_axi_awlock,
    input  wire [3:0]                cpu_axi_awcache,
    input  wire [2:0]                cpu_axi_awprot,
    input  wire [3:0]                cpu_axi_awqos,
    input  wire                      cpu_axi_awvalid,
    output wire                      cpu_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0] cpu_axi_wdata,
    input  wire [7:0]                cpu_axi_wstrb,
    input  wire                      cpu_axi_wlast,
    input  wire                      cpu_axi_wvalid,
    output wire                      cpu_axi_wready,

    output wire [AXI_ID_WIDTH-1:0]   cpu_axi_bid,
    output wire [1:0]                cpu_axi_bresp,
    output wire                      cpu_axi_bvalid,
    input  wire                      cpu_axi_bready,

    input  wire [AXI_ID_WIDTH-1:0]   cpu_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0] cpu_axi_araddr,
    input  wire [7:0]                cpu_axi_arlen,
    input  wire [2:0]                cpu_axi_arsize,
    input  wire [1:0]                cpu_axi_arburst,
    input  wire                      cpu_axi_arlock,
    input  wire [3:0]                cpu_axi_arcache,
    input  wire [2:0]                cpu_axi_arprot,
    input  wire [3:0]                cpu_axi_arqos,
    input  wire                      cpu_axi_arvalid,
    output wire                      cpu_axi_arready,

    output wire [AXI_ID_WIDTH-1:0]   cpu_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0] cpu_axi_rdata,
    output wire [1:0]                cpu_axi_rresp,
    output wire                      cpu_axi_rlast,
    output wire                      cpu_axi_rvalid,
    input  wire                      cpu_axi_rready,

    // Interrupt Outputs (to CPU PIC Controller)
    output wire                      irq_dma,
    output wire                      irq_crc,
    output wire                      irq_timer_enh,
    output wire                      irq_timer_std,
    output wire                      irq_uart,
    output wire                      irq_gpio
);

    // =========================================================================
    // 1. UART Controller (Full TX/RX + AXI-Lite CSRs + Streaming to DMA)
    // =========================================================================
    wire [7:0] uart_stream_data;
    wire       uart_stream_valid;
    wire       uart_stream_ready;

    wire [AXI_ADDR_WIDTH-1:0] uart_s_awaddr;
    wire [2:0]                uart_s_awprot;
    wire                      uart_s_awvalid;
    wire                      uart_s_awready;
    wire [31:0]               uart_s_wdata;
    wire [3:0]                uart_s_wstrb;
    wire                      uart_s_wvalid;
    wire                      uart_s_wready;
    wire [1:0]                uart_s_bresp;
    wire                      uart_s_bvalid;
    wire                      uart_s_bready;
    wire [AXI_ADDR_WIDTH-1:0] uart_s_araddr;
    wire [2:0]                uart_s_arprot;
    wire                      uart_s_arvalid;
    wire                      uart_s_arready;
    wire [31:0]               uart_s_rdata;
    wire [1:0]                uart_s_rresp;
    wire                      uart_s_rvalid;
    wire                      uart_s_rready;

    uart_top #(
        .ADDR_WIDTH   (AXI_ADDR_WIDTH),
        .DATA_WIDTH   (32),
        .CLKS_PER_BIT (UART_CLKS_PER_BIT)
    ) u_uart (
        .clk          (clk),
        .rst_n        (rst_n),

        // AXI4-Lite
        .s_axi_awaddr (uart_s_awaddr),
        .s_axi_awprot (uart_s_awprot),
        .s_axi_awvalid(uart_s_awvalid),
        .s_axi_awready(uart_s_awready),
        .s_axi_wdata  (uart_s_wdata),
        .s_axi_wstrb  (uart_s_wstrb),
        .s_axi_wvalid (uart_s_wvalid),
        .s_axi_wready (uart_s_wready),
        .s_axi_bresp  (uart_s_bresp),
        .s_axi_bvalid (uart_s_bvalid),
        .s_axi_bready (uart_s_bready),
        .s_axi_araddr (uart_s_araddr),
        .s_axi_arprot (uart_s_arprot),
        .s_axi_arvalid(uart_s_arvalid),
        .s_axi_arready(uart_s_arready),
        .s_axi_rdata  (uart_s_rdata),
        .s_axi_rresp  (uart_s_rresp),
        .s_axi_rvalid (uart_s_rvalid),
        .s_axi_rready (uart_s_rready),

        // Physical Pins
        .uart_rx      (uart_rx),
        .uart_tx      (uart_tx),

        // Streaming to DMA
        .m_axis_tdata (uart_stream_data),
        .m_axis_tvalid(uart_stream_valid),
        .m_axis_tready(uart_stream_ready),

        // Interrupt
        .irq_uart     (irq_uart)
    );

    // =========================================================================
    // 2. Monitoring & Status Wires
    // =========================================================================
    wire dma_active;
    wire dma_done;
    wire dma_error;

    wire crc_busy;
    wire crc_done;
    wire crc_pass;
    wire crc_fail;

    // =========================================================================
    // 3. DMA Controller (AXI4-Lite Slave + 64-bit AXI4 Write Master)
    // =========================================================================
    wire [AXI_ADDR_WIDTH-1:0] dma_m_awaddr;
    wire [7:0]                dma_m_awlen;
    wire [2:0]                dma_m_awsize;
    wire [1:0]                dma_m_awburst;
    wire                      dma_m_awlock;
    wire [3:0]                dma_m_awcache;
    wire [2:0]                dma_m_awprot;
    wire [3:0]                dma_m_awqos;
    wire                      dma_m_awvalid;
    wire                      dma_m_awready;

    wire [AXI_DATA_WIDTH-1:0] dma_m_wdata;
    wire [7:0]                dma_m_wstrb;
    wire                      dma_m_wlast;
    wire                      dma_m_wvalid;
    wire                      dma_m_wready;

    wire [1:0]                dma_m_bresp;
    wire                      dma_m_bvalid;
    wire                      dma_m_bready;

    wire [AXI_ADDR_WIDTH-1:0] dma_s_awaddr;
    wire [2:0]                dma_s_awprot;
    wire                      dma_s_awvalid;
    wire                      dma_s_awready;
    wire [31:0]               dma_s_wdata;
    wire [3:0]                dma_s_wstrb;
    wire                      dma_s_wvalid;
    wire                      dma_s_wready;
    wire [1:0]                dma_s_bresp;
    wire                      dma_s_bvalid;
    wire                      dma_s_bready;
    wire [AXI_ADDR_WIDTH-1:0] dma_s_araddr;
    wire [2:0]                dma_s_arprot;
    wire                      dma_s_arvalid;
    wire                      dma_s_arready;
    wire [31:0]               dma_s_rdata;
    wire [1:0]                dma_s_rresp;
    wire                      dma_s_rvalid;
    wire                      dma_s_rready;

    dma_uart_to_mem #(
        .ADDR_W    (AXI_ADDR_WIDTH),
        .FIFO_DEPTH(16)
    ) u_dma (
        .clk           (clk),
        .rst_n         (rst_n),

        .s_axil_awaddr (dma_s_awaddr),
        .s_axil_awprot (dma_s_awprot),
        .s_axil_awvalid(dma_s_awvalid),
        .s_axil_awready(dma_s_awready),
        .s_axil_wdata  (dma_s_wdata),
        .s_axil_wstrb  (dma_s_wstrb),
        .s_axil_wvalid (dma_s_wvalid),
        .s_axil_wready (dma_s_wready),
        .s_axil_bresp  (dma_s_bresp),
        .s_axil_bvalid (dma_s_bvalid),
        .s_axil_bready (dma_s_bready),
        .s_axil_araddr (dma_s_araddr),
        .s_axil_arprot (dma_s_arprot),
        .s_axil_arvalid(dma_s_arvalid),
        .s_axil_arready(dma_s_arready),
        .s_axil_rdata  (dma_s_rdata),
        .s_axil_rresp  (dma_s_rresp),
        .s_axil_rvalid (dma_s_rvalid),
        .s_axil_rready (dma_s_rready),

        .uart_rx_data  (uart_stream_data),
        .uart_rx_valid (uart_stream_valid),
        .uart_rx_ready (uart_stream_ready),

        .m_axi_awaddr  (dma_m_awaddr),
        .m_axi_awlen   (dma_m_awlen),
        .m_axi_awsize  (dma_m_awsize),
        .m_axi_awburst (dma_m_awburst),
        .m_axi_awlock  (dma_m_awlock),
        .m_axi_awcache (dma_m_awcache),
        .m_axi_awprot  (dma_m_awprot),
        .m_axi_awqos   (dma_m_awqos),
        .m_axi_awvalid (dma_m_awvalid),
        .m_axi_awready (dma_m_awready),
        .m_axi_wdata   (dma_m_wdata),
        .m_axi_wstrb   (dma_m_wstrb),
        .m_axi_wlast   (dma_m_wlast),
        .m_axi_wvalid  (dma_m_wvalid),
        .m_axi_wready  (dma_m_wready),
        .m_axi_bresp   (dma_m_bresp),
        .m_axi_bvalid  (dma_m_bvalid),
        .m_axi_bready  (dma_m_bready),

        .dma_active    (dma_active),
        .dma_done      (dma_done),
        .dma_error     (dma_error),
        .irq_o         (irq_dma)
    );

    // =========================================================================
    // 4. CRC-32 Engine (AXI4-Lite Slave + 64-bit AXI4 Read Master)
    // =========================================================================
    wire [AXI_ID_WIDTH-1:0]   crc_m_arid;
    wire [AXI_ADDR_WIDTH-1:0] crc_m_araddr;
    wire [7:0]                crc_m_arlen;
    wire [2:0]                crc_m_arsize;
    wire [1:0]                crc_m_arburst;
    wire                      crc_m_arlock;
    wire [3:0]                crc_m_arcache;
    wire [2:0]                crc_m_arprot;
    wire [3:0]                crc_m_arqos;
    wire                      crc_m_arvalid;
    wire                      crc_m_arready;

    wire [AXI_ID_WIDTH-1:0]   crc_m_rid;
    wire [AXI_DATA_WIDTH-1:0] crc_m_rdata;
    wire [1:0]                crc_m_rresp;
    wire                      crc_m_rlast;
    wire                      crc_m_rvalid;
    wire                      crc_m_rready;

    wire [AXI_ADDR_WIDTH-1:0] crc_s_awaddr;
    wire [2:0]                crc_s_awprot;
    wire                      crc_s_awvalid;
    wire                      crc_s_awready;
    wire [31:0]               crc_s_wdata;
    wire [3:0]                crc_s_wstrb;
    wire                      crc_s_wvalid;
    wire                      crc_s_wready;
    wire [1:0]                crc_s_bresp;
    wire                      crc_s_bvalid;
    wire                      crc_s_bready;
    wire [AXI_ADDR_WIDTH-1:0] crc_s_araddr;
    wire [2:0]                crc_s_arprot;
    wire                      crc_s_arvalid;
    wire                      crc_s_arready;
    wire [31:0]               crc_s_rdata;
    wire [1:0]                crc_s_rresp;
    wire                      crc_s_rvalid;
    wire                      crc_s_rready;

    crc32_top #(
        .AXIL_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXIM_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXIM_ID_WIDTH  (AXI_ID_WIDTH),
        .MAX_BURST_LEN  (16)
    ) u_crc32 (
        .clk          (clk),
        .rst_n        (rst_n),

        .s_axi_awaddr (crc_s_awaddr),
        .s_axi_awprot (crc_s_awprot),
        .s_axi_awvalid(crc_s_awvalid),
        .s_axi_awready(crc_s_awready),
        .s_axi_wdata  (crc_s_wdata),
        .s_axi_wstrb  (crc_s_wstrb),
        .s_axi_wvalid (crc_s_wvalid),
        .s_axi_wready (crc_s_wready),
        .s_axi_bresp  (crc_s_bresp),
        .s_axi_bvalid (crc_s_bvalid),
        .s_axi_bready (crc_s_bready),
        .s_axi_araddr (crc_s_araddr),
        .s_axi_arprot (crc_s_arprot),
        .s_axi_arvalid(crc_s_arvalid),
        .s_axi_arready(crc_s_arready),
        .s_axi_rdata  (crc_s_rdata),
        .s_axi_rresp  (crc_s_rresp),
        .s_axi_rvalid (crc_s_rvalid),
        .s_axi_rready (crc_s_rready),

        .m_axi_arid   (crc_m_arid),
        .m_axi_araddr (crc_m_araddr),
        .m_axi_arlen  (crc_m_arlen),
        .m_axi_arsize (crc_m_arsize),
        .m_axi_arburst(crc_m_arburst),
        .m_axi_arlock (crc_m_arlock),
        .m_axi_arcache(crc_m_arcache),
        .m_axi_arprot (crc_m_arprot),
        .m_axi_arqos  (crc_m_arqos),
        .m_axi_arvalid(crc_m_arvalid),
        .m_axi_arready(crc_m_arready),
        .m_axi_rid    (crc_m_rid),
        .m_axi_rdata  (crc_m_rdata),
        .m_axi_rresp  (crc_m_rresp),
        .m_axi_rlast  (crc_m_rlast),
        .m_axi_rvalid (crc_m_rvalid),
        .m_axi_rready (crc_m_rready),

        .irq_o        (irq_crc),
        .crc_busy     (crc_busy),
        .crc_done     (crc_done),
        .crc_pass     (crc_pass),
        .crc_fail     (crc_fail)
    );

    // =========================================================================
    // 5. Enhanced Timer (Hardware Profiler & Watchdogs)
    // =========================================================================
    wire [AXI_ADDR_WIDTH-1:0] tmr_enh_awaddr;
    wire [2:0]                tmr_enh_awprot;
    wire                      tmr_enh_awvalid;
    wire                      tmr_enh_awready;
    wire [31:0]               tmr_enh_wdata;
    wire [3:0]                tmr_enh_wstrb;
    wire                      tmr_enh_wvalid;
    wire                      tmr_enh_wready;
    wire [1:0]                tmr_enh_bresp;
    wire                      tmr_enh_bvalid;
    wire                      tmr_enh_bready;
    wire [AXI_ADDR_WIDTH-1:0] tmr_enh_araddr;
    wire [2:0]                tmr_enh_arprot;
    wire                      tmr_enh_arvalid;
    wire                      tmr_enh_arready;
    wire [31:0]               tmr_enh_rdata;
    wire [1:0]                tmr_enh_rresp;
    wire                      tmr_enh_rvalid;
    wire                      tmr_enh_rready;

    enhanced_timer #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) u_enhanced_timer (
        .clk              (clk),
        .rst_n            (rst_n),

        .s_axi_awaddr     (tmr_enh_awaddr),
        .s_axi_awprot     (tmr_enh_awprot),
        .s_axi_awvalid    (tmr_enh_awvalid),
        .s_axi_awready    (tmr_enh_awready),
        .s_axi_wdata      (tmr_enh_wdata),
        .s_axi_wstrb      (tmr_enh_wstrb),
        .s_axi_wvalid     (tmr_enh_wvalid),
        .s_axi_wready     (tmr_enh_wready),
        .s_axi_bresp      (tmr_enh_bresp),
        .s_axi_bvalid     (tmr_enh_bvalid),
        .s_axi_bready     (tmr_enh_bready),
        .s_axi_araddr     (tmr_enh_araddr),
        .s_axi_arprot     (tmr_enh_arprot),
        .s_axi_arvalid    (tmr_enh_arvalid),
        .s_axi_arready    (tmr_enh_arready),
        .s_axi_rdata      (tmr_enh_rdata),
        .s_axi_rresp      (tmr_enh_rresp),
        .s_axi_rvalid     (tmr_enh_rvalid),
        .s_axi_rready     (tmr_enh_rready),

        .dma_active       (dma_active),
        .dma_done         (dma_done),
        .crc_busy         (crc_busy),
        .crc_done         (crc_done),

        .irq_timer        (irq_timer_enh)
    );

    // =========================================================================
    // 6. Standard Timer IP
    // =========================================================================
    wire [AXI_ADDR_WIDTH-1:0] tmr_std_awaddr;
    wire [2:0]                tmr_std_awprot;
    wire                      tmr_std_awvalid;
    wire                      tmr_std_awready;
    wire [31:0]               tmr_std_wdata;
    wire [3:0]                tmr_std_wstrb;
    wire                      tmr_std_wvalid;
    wire                      tmr_std_wready;
    wire [1:0]                tmr_std_bresp;
    wire                      tmr_std_bvalid;
    wire                      tmr_std_bready;
    wire [AXI_ADDR_WIDTH-1:0] tmr_std_araddr;
    wire [2:0]                tmr_std_arprot;
    wire                      tmr_std_arvalid;
    wire                      tmr_std_arready;
    wire [31:0]               tmr_std_rdata;
    wire [1:0]                tmr_std_rresp;
    wire                      tmr_std_rvalid;
    wire                      tmr_std_rready;

    timer_std #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) u_timer_std (
        .clk          (clk),
        .rst_n        (rst_n),

        .s_axi_awaddr (tmr_std_awaddr),
        .s_axi_awprot (tmr_std_awprot),
        .s_axi_awvalid(tmr_std_awvalid),
        .s_axi_awready(tmr_std_awready),
        .s_axi_wdata  (tmr_std_wdata),
        .s_axi_wstrb  (tmr_std_wstrb),
        .s_axi_wvalid (tmr_std_wvalid),
        .s_axi_wready (tmr_std_wready),
        .s_axi_bresp  (tmr_std_bresp),
        .s_axi_bvalid (tmr_std_bvalid),
        .s_axi_bready (tmr_std_bready),
        .s_axi_araddr (tmr_std_araddr),
        .s_axi_arprot (tmr_std_arprot),
        .s_axi_arvalid(tmr_std_arvalid),
        .s_axi_arready(tmr_std_arready),
        .s_axi_rdata  (tmr_std_rdata),
        .s_axi_rresp  (tmr_std_rresp),
        .s_axi_rvalid (tmr_std_rvalid),
        .s_axi_rready (tmr_std_rready),

        .irq_timer    (irq_timer_std)
    );

    // =========================================================================
    // 7. 32-bit GPIO Controller
    // =========================================================================
    wire [AXI_ADDR_WIDTH-1:0] gpio_s_awaddr;
    wire [2:0]                gpio_s_awprot;
    wire                      gpio_s_awvalid;
    wire                      gpio_s_awready;
    wire [31:0]               gpio_s_wdata;
    wire [3:0]                gpio_s_wstrb;
    wire                      gpio_s_wvalid;
    wire                      gpio_s_wready;
    wire [1:0]                gpio_s_bresp;
    wire                      gpio_s_bvalid;
    wire                      gpio_s_bready;
    wire [AXI_ADDR_WIDTH-1:0] gpio_s_araddr;
    wire [2:0]                gpio_s_arprot;
    wire                      gpio_s_arvalid;
    wire                      gpio_s_arready;
    wire [31:0]               gpio_s_rdata;
    wire [1:0]                gpio_s_rresp;
    wire                      gpio_s_rvalid;
    wire                      gpio_s_rready;

    gpio_top #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(32),
        .NUM_GPIOS (NUM_GPIOS)
    ) u_gpio (
        .clk          (clk),
        .rst_n        (rst_n),

        .s_axi_awaddr (gpio_s_awaddr),
        .s_axi_awprot (gpio_s_awprot),
        .s_axi_awvalid(gpio_s_awvalid),
        .s_axi_awready(gpio_s_awready),
        .s_axi_wdata  (gpio_s_wdata),
        .s_axi_wstrb  (gpio_s_wstrb),
        .s_axi_wvalid (gpio_s_wvalid),
        .s_axi_wready (gpio_s_wready),
        .s_axi_bresp  (gpio_s_bresp),
        .s_axi_bvalid (gpio_s_bvalid),
        .s_axi_bready (gpio_s_bready),
        .s_axi_araddr (gpio_s_araddr),
        .s_axi_arprot (gpio_s_arprot),
        .s_axi_arvalid(gpio_s_arvalid),
        .s_axi_arready(gpio_s_arready),
        .s_axi_rdata  (gpio_s_rdata),
        .s_axi_rresp  (gpio_s_rresp),
        .s_axi_rvalid (gpio_s_rvalid),
        .s_axi_rready (gpio_s_rready),

        .gpio_i       (gpio_i),
        .gpio_o       (gpio_o),
        .gpio_oe      (gpio_oe),

        .irq_gpio     (irq_gpio)
    );

    // =========================================================================
    // 8. 7-Segment Display Controller
    // =========================================================================
    wire [AXI_ADDR_WIDTH-1:0] seg_s_awaddr;
    wire [2:0]                seg_s_awprot;
    wire                      seg_s_awvalid;
    wire                      seg_s_awready;
    wire [31:0]               seg_s_wdata;
    wire [3:0]                seg_s_wstrb;
    wire                      seg_s_wvalid;
    wire                      seg_s_wready;
    wire [1:0]                seg_s_bresp;
    wire                      seg_s_bvalid;
    wire                      seg_s_bready;
    wire [AXI_ADDR_WIDTH-1:0] seg_s_araddr;
    wire [2:0]                seg_s_arprot;
    wire                      seg_s_arvalid;
    wire                      seg_s_arready;
    wire [31:0]               seg_s_rdata;
    wire [1:0]                seg_s_rresp;
    wire                      seg_s_rvalid;
    wire                      seg_s_rready;

    wire [1:0] hw_status_crc = crc_pass ? 2'b01 : (crc_fail ? 2'b10 : 2'b00);

    seven_segment_ctrl #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) u_seven_seg (
        .clk          (clk),
        .rst_n        (rst_n),

        .s_axi_awaddr (seg_s_awaddr),
        .s_axi_awprot (seg_s_awprot),
        .s_axi_awvalid(seg_s_awvalid),
        .s_axi_awready(seg_s_awready),
        .s_axi_wdata  (seg_s_wdata),
        .s_axi_wstrb  (seg_s_wstrb),
        .s_axi_wvalid (seg_s_wvalid),
        .s_axi_wready (seg_s_wready),
        .s_axi_bresp  (seg_s_bresp),
        .s_axi_bvalid (seg_s_bvalid),
        .s_axi_bready (seg_s_bready),
        .s_axi_araddr (seg_s_araddr),
        .s_axi_arprot (seg_s_arprot),
        .s_axi_arvalid(seg_s_arvalid),
        .s_axi_arready(seg_s_arready),
        .s_axi_rdata  (seg_s_rdata),
        .s_axi_rresp  (seg_s_rresp),
        .s_axi_rvalid (seg_s_rvalid),
        .s_axi_rready (seg_s_rready),

        .hw_status_i  (hw_status_crc),
        .hw_status_en (crc_done),

        .seg_cathodes (seg_cathodes),
        .seg_anodes   (seg_anodes),
        .led_idle     (led_idle),
        .led_pass     (led_pass),
        .led_fail     (led_fail)
    );

    // =========================================================================
    // 9. AXI4 to AXI4-Lite Bridge (7 Peripheral Ports)
    // =========================================================================
    wire [AXI_ID_WIDTH-1:0]   bridge_axi_awid;
    wire [AXI_ADDR_WIDTH-1:0] bridge_axi_awaddr;
    wire [7:0]                bridge_axi_awlen;
    wire [2:0]                bridge_axi_awsize;
    wire [1:0]                bridge_axi_awburst;
    wire                      bridge_axi_awlock;
    wire [3:0]                bridge_axi_awcache;
    wire [2:0]                bridge_axi_awprot;
    wire [3:0]                bridge_axi_awqos;
    wire                      bridge_axi_awvalid;
    wire                      bridge_axi_awready;

    wire [AXI_DATA_WIDTH-1:0] bridge_axi_wdata;
    wire [7:0]                bridge_axi_wstrb;
    wire                      bridge_axi_wlast;
    wire                      bridge_axi_wvalid;
    wire                      bridge_axi_wready;

    wire [AXI_ID_WIDTH-1:0]   bridge_axi_bid;
    wire [1:0]                bridge_axi_bresp;
    wire                      bridge_axi_bvalid;
    wire                      bridge_axi_bready;

    wire [AXI_ID_WIDTH-1:0]   bridge_axi_arid;
    wire [AXI_ADDR_WIDTH-1:0] bridge_axi_araddr;
    wire [7:0]                bridge_axi_arlen;
    wire [2:0]                bridge_axi_arsize;
    wire [1:0]                bridge_axi_arburst;
    wire                      bridge_axi_arlock;
    wire [3:0]                bridge_axi_arcache;
    wire [2:0]                bridge_axi_arprot;
    wire [3:0]                bridge_axi_arqos;
    wire                      bridge_axi_arvalid;
    wire                      bridge_axi_arready;

    wire [AXI_ID_WIDTH-1:0]   bridge_axi_rid;
    wire [AXI_DATA_WIDTH-1:0] bridge_axi_rdata;
    wire [1:0]                bridge_axi_rresp;
    wire                      bridge_axi_rlast;
    wire                      bridge_axi_rvalid;
    wire                      bridge_axi_rready;

    axi4_to_axilite_bridge #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH   (AXI_ID_WIDTH)
    ) u_bridge (
        .clk            (clk),
        .rst_n          (rst_n),

        // AXI4 full slave from interconnect
        .s_axi_awid     (bridge_axi_awid),
        .s_axi_awaddr   (bridge_axi_awaddr),
        .s_axi_awlen    (bridge_axi_awlen),
        .s_axi_awsize   (bridge_axi_awsize),
        .s_axi_awburst  (bridge_axi_awburst),
        .s_axi_awlock   (bridge_axi_awlock),
        .s_axi_awcache  (bridge_axi_awcache),
        .s_axi_awprot   (bridge_axi_awprot),
        .s_axi_awqos    (bridge_axi_awqos),
        .s_axi_awvalid  (bridge_axi_awvalid),
        .s_axi_awready  (bridge_axi_awready),

        .s_axi_wdata    (bridge_axi_wdata),
        .s_axi_wstrb    (bridge_axi_wstrb),
        .s_axi_wlast    (bridge_axi_wlast),
        .s_axi_wvalid   (bridge_axi_wvalid),
        .s_axi_wready   (bridge_axi_wready),

        .s_axi_bid      (bridge_axi_bid),
        .s_axi_bresp    (bridge_axi_bresp),
        .s_axi_bvalid   (bridge_axi_bvalid),
        .s_axi_bready   (bridge_axi_bready),

        .s_axi_arid     (bridge_axi_arid),
        .s_axi_araddr   (bridge_axi_araddr),
        .s_axi_arlen    (bridge_axi_arlen),
        .s_axi_arsize   (bridge_axi_arsize),
        .s_axi_arburst  (bridge_axi_arburst),
        .s_axi_arlock   (bridge_axi_arlock),
        .s_axi_arcache  (bridge_axi_arcache),
        .s_axi_arprot   (bridge_axi_arprot),
        .s_axi_arqos    (bridge_axi_arqos),
        .s_axi_arvalid  (bridge_axi_arvalid),
        .s_axi_arready  (bridge_axi_arready),

        .s_axi_rid      (bridge_axi_rid),
        .s_axi_rdata    (bridge_axi_rdata),
        .s_axi_rresp    (bridge_axi_rresp),
        .s_axi_rlast    (bridge_axi_rlast),
        .s_axi_rvalid   (bridge_axi_rvalid),
        .s_axi_rready   (bridge_axi_rready),

        // Port 0: DMA
        .m0_axil_awaddr (dma_s_awaddr),
        .m0_axil_awprot (dma_s_awprot),
        .m0_axil_awvalid(dma_s_awvalid),
        .m0_axil_awready(dma_s_awready),
        .m0_axil_wdata  (dma_s_wdata),
        .m0_axil_wstrb  (dma_s_wstrb),
        .m0_axil_wvalid (dma_s_wvalid),
        .m0_axil_wready (dma_s_wready),
        .m0_axil_bresp  (dma_s_bresp),
        .m0_axil_bvalid (dma_s_bvalid),
        .m0_axil_bready (dma_s_bready),
        .m0_axil_araddr (dma_s_araddr),
        .m0_axil_arprot (dma_s_arprot),
        .m0_axil_arvalid(dma_s_arvalid),
        .m0_axil_arready(dma_s_arready),
        .m0_axil_rdata  (dma_s_rdata),
        .m0_axil_rresp  (dma_s_rresp),
        .m0_axil_rvalid (dma_s_rvalid),
        .m0_axil_rready (dma_s_rready),

        // Port 1: CRC
        .m1_axil_awaddr (crc_s_awaddr),
        .m1_axil_awprot (crc_s_awprot),
        .m1_axil_awvalid(crc_s_awvalid),
        .m1_axil_awready(crc_s_awready),
        .m1_axil_wdata  (crc_s_wdata),
        .m1_axil_wstrb  (crc_s_wstrb),
        .m1_axil_wvalid (crc_s_wvalid),
        .m1_axil_wready (crc_s_wready),
        .m1_axil_bresp  (crc_s_bresp),
        .m1_axil_bvalid (crc_s_bvalid),
        .m1_axil_bready (crc_s_bready),
        .m1_axil_araddr (crc_s_araddr),
        .m1_axil_arprot (crc_s_arprot),
        .m1_axil_arvalid(crc_s_arvalid),
        .m1_axil_arready(crc_s_arready),
        .m1_axil_rdata  (crc_s_rdata),
        .m1_axil_rresp  (crc_s_rresp),
        .m1_axil_rvalid (crc_s_rvalid),
        .m1_axil_rready (crc_s_rready),

        // Port 2: Enhanced Timer
        .m2_axil_awaddr (tmr_enh_awaddr),
        .m2_axil_awprot (tmr_enh_awprot),
        .m2_axil_awvalid(tmr_enh_awvalid),
        .m2_axil_awready(tmr_enh_awready),
        .m2_axil_wdata  (tmr_enh_wdata),
        .m2_axil_wstrb  (tmr_enh_wstrb),
        .m2_axil_wvalid (tmr_enh_wvalid),
        .m2_axil_wready (tmr_enh_wready),
        .m2_axil_bresp  (tmr_enh_bresp),
        .m2_axil_bvalid (tmr_enh_bvalid),
        .m2_axil_bready (tmr_enh_bready),
        .m2_axil_araddr (tmr_enh_araddr),
        .m2_axil_arprot (tmr_enh_arprot),
        .m2_axil_arvalid(tmr_enh_arvalid),
        .m2_axil_arready(tmr_enh_arready),
        .m2_axil_rdata  (tmr_enh_rdata),
        .m2_axil_rresp  (tmr_enh_rresp),
        .m2_axil_rvalid (tmr_enh_rvalid),
        .m2_axil_rready (tmr_enh_rready),

        // Port 3: 7-Segment Display
        .m3_axil_awaddr (seg_s_awaddr),
        .m3_axil_awprot (seg_s_awprot),
        .m3_axil_awvalid(seg_s_awvalid),
        .m3_axil_awready(seg_s_awready),
        .m3_axil_wdata  (seg_s_wdata),
        .m3_axil_wstrb  (seg_s_wstrb),
        .m3_axil_wvalid (seg_s_wvalid),
        .m3_axil_wready (seg_s_wready),
        .m3_axil_bresp  (seg_s_bresp),
        .m3_axil_bvalid (seg_s_bvalid),
        .m3_axil_bready (seg_s_bready),
        .m3_axil_araddr (seg_s_araddr),
        .m3_axil_arprot (seg_s_arprot),
        .m3_axil_arvalid(seg_s_arvalid),
        .m3_axil_arready(seg_s_arready),
        .m3_axil_rdata  (seg_s_rdata),
        .m3_axil_rresp  (seg_s_rresp),
        .m3_axil_rvalid (seg_s_rvalid),
        .m3_axil_rready (seg_s_rready),

        // Port 4: UART Controller
        .m4_axil_awaddr (uart_s_awaddr),
        .m4_axil_awprot (uart_s_awprot),
        .m4_axil_awvalid(uart_s_awvalid),
        .m4_axil_awready(uart_s_awready),
        .m4_axil_wdata  (uart_s_wdata),
        .m4_axil_wstrb  (uart_s_wstrb),
        .m4_axil_wvalid (uart_s_wvalid),
        .m4_axil_wready (uart_s_wready),
        .m4_axil_bresp  (uart_s_bresp),
        .m4_axil_bvalid (uart_s_bvalid),
        .m4_axil_bready (uart_s_bready),
        .m4_axil_araddr (uart_s_araddr),
        .m4_axil_arprot (uart_s_arprot),
        .m4_axil_arvalid(uart_s_arvalid),
        .m4_axil_arready(uart_s_arready),
        .m4_axil_rdata  (uart_s_rdata),
        .m4_axil_rresp  (uart_s_rresp),
        .m4_axil_rvalid (uart_s_rvalid),
        .m4_axil_rready (uart_s_rready),

        // Port 5: Standard Timer
        .m5_axil_awaddr (tmr_std_awaddr),
        .m5_axil_awprot (tmr_std_awprot),
        .m5_axil_awvalid(tmr_std_awvalid),
        .m5_axil_awready(tmr_std_awready),
        .m5_axil_wdata  (tmr_std_wdata),
        .m5_axil_wstrb  (tmr_std_wstrb),
        .m5_axil_wvalid (tmr_std_wvalid),
        .m5_axil_wready (tmr_std_wready),
        .m5_axil_bresp  (tmr_std_bresp),
        .m5_axil_bvalid (tmr_std_bvalid),
        .m5_axil_bready (tmr_std_bready),
        .m5_axil_araddr (tmr_std_araddr),
        .m5_axil_arprot (tmr_std_arprot),
        .m5_axil_arvalid(tmr_std_arvalid),
        .m5_axil_arready(tmr_std_arready),
        .m5_axil_rdata  (tmr_std_rdata),
        .m5_axil_rresp  (tmr_std_rresp),
        .m5_axil_rvalid (tmr_std_rvalid),
        .m5_axil_rready (tmr_std_rready),

        // Port 6: GPIO
        .m6_axil_awaddr (gpio_s_awaddr),
        .m6_axil_awprot (gpio_s_awprot),
        .m6_axil_awvalid(gpio_s_awvalid),
        .m6_axil_awready(gpio_s_awready),
        .m6_axil_wdata  (gpio_s_wdata),
        .m6_axil_wstrb  (gpio_s_wstrb),
        .m6_axil_wvalid (gpio_s_wvalid),
        .m6_axil_wready (gpio_s_wready),
        .m6_axil_bresp  (gpio_s_bresp),
        .m6_axil_bvalid (gpio_s_bvalid),
        .m6_axil_bready (gpio_s_bready),
        .m6_axil_araddr (gpio_s_araddr),
        .m6_axil_arprot (gpio_s_arprot),
        .m6_axil_arvalid(gpio_s_arvalid),
        .m6_axil_arready(gpio_s_arready),
        .m6_axil_rdata  (gpio_s_rdata),
        .m6_axil_rresp  (gpio_s_rresp),
        .m6_axil_rvalid (gpio_s_rvalid),
        .m6_axil_rready (gpio_s_rready)
    );

    // =========================================================================
    // 10. System Memory: IMEM (0x0000_0000) & DMEM (0x0000_8000)
    // =========================================================================
    wire [AXI_ID_WIDTH-1:0]   mem_axi_awid;
    wire [AXI_ADDR_WIDTH-1:0] mem_axi_awaddr;
    wire [7:0]                mem_axi_awlen;
    wire [2:0]                mem_axi_awsize;
    wire [1:0]                mem_axi_awburst;
    wire                      mem_axi_awvalid;
    wire                      mem_axi_awready;

    wire [AXI_DATA_WIDTH-1:0] mem_axi_wdata;
    wire [7:0]                mem_axi_wstrb;
    wire                      mem_axi_wlast;
    wire                      mem_axi_wvalid;
    wire                      mem_axi_wready;

    wire [AXI_ID_WIDTH-1:0]   mem_axi_bid;
    wire [1:0]                mem_axi_bresp;
    wire                      mem_axi_bvalid;
    wire                      mem_axi_bready;

    wire [AXI_ID_WIDTH-1:0]   mem_axi_arid;
    wire [AXI_ADDR_WIDTH-1:0] mem_axi_araddr;
    wire [7:0]                mem_axi_arlen;
    wire [2:0]                mem_axi_arsize;
    wire [1:0]                mem_axi_arburst;
    wire                      mem_axi_arvalid;
    wire                      mem_axi_arready;

    wire [AXI_ID_WIDTH-1:0]   mem_axi_rid;
    wire [AXI_DATA_WIDTH-1:0] mem_axi_rdata;
    wire [1:0]                mem_axi_rresp;
    wire                      mem_axi_rlast;
    wire                      mem_axi_rvalid;
    wire                      mem_axi_rready;

    axi4_ram #(
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ID_WIDTH  (AXI_ID_WIDTH),
        .MEM_SIZE  (65536), // 64 KB total (0x0000_0000 - 0x0000_7FFF IMEM, 0x0000_8000 - 0x0000_FFFF DMEM)
        .INIT_FILE (INIT_HEX_FILE)
    ) u_system_ram (
        .clk          (clk),
        .rst_n        (rst_n),

        .s_axi_awid   (mem_axi_awid),
        .s_axi_awaddr (mem_axi_awaddr),
        .s_axi_awlen  (mem_axi_awlen),
        .s_axi_awsize (mem_axi_awsize),
        .s_axi_awburst(mem_axi_awburst),
        .s_axi_awvalid(mem_axi_awvalid),
        .s_axi_awready(mem_axi_awready),

        .s_axi_wdata  (mem_axi_wdata),
        .s_axi_wstrb  (mem_axi_wstrb),
        .s_axi_wlast  (mem_axi_wlast),
        .s_axi_wvalid (mem_axi_wvalid),
        .s_axi_wready (mem_axi_wready),

        .s_axi_bid    (mem_axi_bid),
        .s_axi_bresp  (mem_axi_bresp),
        .s_axi_bvalid (mem_axi_bvalid),
        .s_axi_bready (mem_axi_bready),

        .s_axi_arid   (mem_axi_arid),
        .s_axi_araddr (mem_axi_araddr),
        .s_axi_arlen  (mem_axi_arlen),
        .s_axi_arsize (mem_axi_arsize),
        .s_axi_arburst(mem_axi_arburst),
        .s_axi_arvalid(mem_axi_arvalid),
        .s_axi_arready(mem_axi_arready),

        .s_axi_rid    (mem_axi_rid),
        .s_axi_rdata  (mem_axi_rdata),
        .s_axi_rresp  (mem_axi_rresp),
        .s_axi_rlast  (mem_axi_rlast),
        .s_axi_rvalid (mem_axi_rvalid),
        .s_axi_rready (mem_axi_rready)
    );

    // =========================================================================
    // 11. AXI4 Interconnect Fabric (4 Masters x 2 Slaves)
    // =========================================================================
    wire rst_sync = ~rst_n;

    axi_interconnect_wrap_4x2 #(
        .DATA_WIDTH    (AXI_DATA_WIDTH),
        .ADDR_WIDTH    (AXI_ADDR_WIDTH),
        .ID_WIDTH      (AXI_ID_WIDTH),
        .M00_BASE_ADDR (32'h0000_0000),
        .M00_ADDR_WIDTH(24),
        .M01_BASE_ADDR (32'h8000_0000),
        .M01_ADDR_WIDTH(24)
    ) u_interconnect (
        .clk(clk),
        .rst(rst_sync),

        // Slave 0: CPU Master
        .s00_axi_awid   (cpu_axi_awid),
        .s00_axi_awaddr (cpu_axi_awaddr),
        .s00_axi_awlen  (cpu_axi_awlen),
        .s00_axi_awsize (cpu_axi_awsize),
        .s00_axi_awburst(cpu_axi_awburst),
        .s00_axi_awlock (cpu_axi_awlock),
        .s00_axi_awcache(cpu_axi_awcache),
        .s00_axi_awprot (cpu_axi_awprot),
        .s00_axi_awqos  (cpu_axi_awqos),
        .s00_axi_awuser (1'b0),
        .s00_axi_awvalid(cpu_axi_awvalid),
        .s00_axi_awready(cpu_axi_awready),
        .s00_axi_wdata  (cpu_axi_wdata),
        .s00_axi_wstrb  (cpu_axi_wstrb),
        .s00_axi_wlast  (cpu_axi_wlast),
        .s00_axi_wuser  (1'b0),
        .s00_axi_wvalid (cpu_axi_wvalid),
        .s00_axi_wready (cpu_axi_wready),
        .s00_axi_bid    (cpu_axi_bid),
        .s00_axi_bresp  (cpu_axi_bresp),
        .s00_axi_buser  (),
        .s00_axi_bvalid (cpu_axi_bvalid),
        .s00_axi_bready (cpu_axi_bready),
        .s00_axi_arid   (cpu_axi_arid),
        .s00_axi_araddr (cpu_axi_araddr),
        .s00_axi_arlen  (cpu_axi_arlen),
        .s00_axi_arsize (cpu_axi_arsize),
        .s00_axi_arburst(cpu_axi_arburst),
        .s00_axi_arlock (cpu_axi_arlock),
        .s00_axi_arcache(cpu_axi_arcache),
        .s00_axi_arprot (cpu_axi_arprot),
        .s00_axi_arqos  (cpu_axi_arqos),
        .s00_axi_aruser (1'b0),
        .s00_axi_arvalid(cpu_axi_arvalid),
        .s00_axi_arready(cpu_axi_arready),
        .s00_axi_rid    (cpu_axi_rid),
        .s00_axi_rdata  (cpu_axi_rdata),
        .s00_axi_rresp  (cpu_axi_rresp),
        .s00_axi_rlast  (cpu_axi_rlast),
        .s00_axi_ruser  (),
        .s00_axi_rvalid (cpu_axi_rvalid),
        .s00_axi_rready (cpu_axi_rready),

        // Slave 1: DMA Write Master
        .s01_axi_awid   (8'h01),
        .s01_axi_awaddr (dma_m_awaddr),
        .s01_axi_awlen  (dma_m_awlen),
        .s01_axi_awsize (dma_m_awsize),
        .s01_axi_awburst(dma_m_awburst),
        .s01_axi_awlock (dma_m_awlock),
        .s01_axi_awcache(dma_m_awcache),
        .s01_axi_awprot (dma_m_awprot),
        .s01_axi_awqos  (dma_m_awqos),
        .s01_axi_awuser (1'b0),
        .s01_axi_awvalid(dma_m_awvalid),
        .s01_axi_awready(dma_m_awready),
        .s01_axi_wdata  (dma_m_wdata),
        .s01_axi_wstrb  (dma_m_wstrb),
        .s01_axi_wlast  (dma_m_wlast),
        .s01_axi_wuser  (1'b0),
        .s01_axi_wvalid (dma_m_wvalid),
        .s01_axi_wready (dma_m_wready),
        .s01_axi_bid    (),
        .s01_axi_bresp  (dma_m_bresp),
        .s01_axi_buser  (),
        .s01_axi_bvalid (dma_m_bvalid),
        .s01_axi_bready (dma_m_bready),
        .s01_axi_arid   (8'h01),
        .s01_axi_araddr (32'h0),
        .s01_axi_arlen  (8'h0),
        .s01_axi_arsize (3'h0),
        .s01_axi_arburst(2'h0),
        .s01_axi_arlock (1'b0),
        .s01_axi_arcache(4'h0),
        .s01_axi_arprot (3'h0),
        .s01_axi_arqos  (4'h0),
        .s01_axi_aruser (1'b0),
        .s01_axi_arvalid(1'b0),
        .s01_axi_arready(),
        .s01_axi_rid    (),
        .s01_axi_rdata  (),
        .s01_axi_rresp  (),
        .s01_axi_rlast  (),
        .s01_axi_ruser  (),
        .s01_axi_rvalid (),
        .s01_axi_rready (1'b0),

        // Slave 2: CRC Read Master
        .s02_axi_awid   (8'h02),
        .s02_axi_awaddr (32'h0),
        .s02_axi_awlen  (8'h0),
        .s02_axi_awsize (3'h0),
        .s02_axi_awburst(2'h0),
        .s02_axi_awlock (1'b0),
        .s02_axi_awcache(4'h0),
        .s02_axi_awprot (3'h0),
        .s02_axi_awqos  (4'h0),
        .s02_axi_awuser (1'b0),
        .s02_axi_awvalid(1'b0),
        .s02_axi_awready(),
        .s02_axi_wdata  (64'h0),
        .s02_axi_wstrb  (8'h0),
        .s02_axi_wlast  (1'b0),
        .s02_axi_wuser  (1'b0),
        .s02_axi_wvalid (1'b0),
        .s02_axi_wready (),
        .s02_axi_bid    (),
        .s02_axi_bresp  (),
        .s02_axi_buser  (),
        .s02_axi_bvalid (),
        .s02_axi_bready (1'b0),
        .s02_axi_arid   (crc_m_arid),
        .s02_axi_araddr (crc_m_araddr),
        .s02_axi_arlen  (crc_m_arlen),
        .s02_axi_arsize (crc_m_arsize),
        .s02_axi_arburst(crc_m_arburst),
        .s02_axi_arlock (crc_m_arlock),
        .s02_axi_arcache(crc_m_arcache),
        .s02_axi_arprot (crc_m_arprot),
        .s02_axi_arqos  (crc_m_arqos),
        .s02_axi_aruser (1'b0),
        .s02_axi_arvalid(crc_m_arvalid),
        .s02_axi_arready(crc_m_arready),
        .s02_axi_rid    (crc_m_rid),
        .s02_axi_rdata  (crc_m_rdata),
        .s02_axi_rresp  (crc_m_rresp),
        .s02_axi_rlast  (crc_m_rlast),
        .s02_axi_ruser  (),
        .s02_axi_rvalid (crc_m_rvalid),
        .s02_axi_rready (crc_m_rready),

        // Slave 3: Unused
        .s03_axi_awid   (8'h03),
        .s03_axi_awaddr (32'h0),
        .s03_axi_awlen  (8'h0),
        .s03_axi_awsize (3'h0),
        .s03_axi_awburst(2'h0),
        .s03_axi_awlock (1'b0),
        .s03_axi_awcache(4'h0),
        .s03_axi_awprot (3'h0),
        .s03_axi_awqos  (4'h0),
        .s03_axi_awuser (1'b0),
        .s03_axi_awvalid(1'b0),
        .s03_axi_awready(),
        .s03_axi_wdata  (64'h0),
        .s03_axi_wstrb  (8'h0),
        .s03_axi_wlast  (1'b0),
        .s03_axi_wuser  (1'b0),
        .s03_axi_wvalid (1'b0),
        .s03_axi_wready (),
        .s03_axi_bid    (),
        .s03_axi_bresp  (),
        .s03_axi_buser  (),
        .s03_axi_bvalid (),
        .s03_axi_bready (1'b0),
        .s03_axi_arid   (8'h03),
        .s03_axi_araddr (32'h0),
        .s03_axi_arlen  (8'h0),
        .s03_axi_arsize (3'h0),
        .s03_axi_arburst(2'h0),
        .s03_axi_arlock (1'b0),
        .s03_axi_arcache(4'h0),
        .s03_axi_arprot (3'h0),
        .s03_axi_arqos  (4'h0),
        .s03_axi_aruser (1'b0),
        .s03_axi_arvalid(1'b0),
        .s03_axi_arready(),
        .s03_axi_rid    (),
        .s03_axi_rdata  (),
        .s03_axi_rresp  (),
        .s03_axi_rlast  (),
        .s03_axi_ruser  (),
        .s03_axi_rvalid (),
        .s03_axi_rready (1'b0),

        // Master 0: System Memory
        .m00_axi_awid   (mem_axi_awid),
        .m00_axi_awaddr (mem_axi_awaddr),
        .m00_axi_awlen  (mem_axi_awlen),
        .m00_axi_awsize (mem_axi_awsize),
        .m00_axi_awburst(mem_axi_awburst),
        .m00_axi_awlock (),
        .m00_axi_awcache(),
        .m00_axi_awprot (),
        .m00_axi_awqos  (),
        .m00_axi_awregion(),
        .m00_axi_awuser (),
        .m00_axi_awvalid(mem_axi_awvalid),
        .m00_axi_awready(mem_axi_awready),
        .m00_axi_wdata  (mem_axi_wdata),
        .m00_axi_wstrb  (mem_axi_wstrb),
        .m00_axi_wlast  (mem_axi_wlast),
        .m00_axi_wuser  (),
        .m00_axi_wvalid (mem_axi_wvalid),
        .m00_axi_wready (mem_axi_wready),
        .m00_axi_bid    (mem_axi_bid),
        .m00_axi_bresp  (mem_axi_bresp),
        .m00_axi_buser  (1'b0),
        .m00_axi_bvalid (mem_axi_bvalid),
        .m00_axi_bready (mem_axi_bready),
        .m00_axi_arid   (mem_axi_arid),
        .m00_axi_araddr (mem_axi_araddr),
        .m00_axi_arlen  (mem_axi_arlen),
        .m00_axi_arsize (mem_axi_arsize),
        .m00_axi_arburst(mem_axi_arburst),
        .m00_axi_arlock (),
        .m00_axi_arcache(),
        .m00_axi_arprot (),
        .m00_axi_arqos  (),
        .m00_axi_arregion(),
        .m00_axi_aruser (),
        .m00_axi_arvalid(mem_axi_arvalid),
        .m00_axi_arready(mem_axi_arready),
        .m00_axi_rid    (mem_axi_rid),
        .m00_axi_rdata  (mem_axi_rdata),
        .m00_axi_rresp  (mem_axi_rresp),
        .m00_axi_rlast  (mem_axi_rlast),
        .m00_axi_ruser  (1'b0),
        .m00_axi_rvalid (mem_axi_rvalid),
        .m00_axi_rready (mem_axi_rready),

        // Master 1: Peripheral Bridge
        .m01_axi_awid   (bridge_axi_awid),
        .m01_axi_awaddr (bridge_axi_awaddr),
        .m01_axi_awlen  (bridge_axi_awlen),
        .m01_axi_awsize (bridge_axi_awsize),
        .m01_axi_awburst(bridge_axi_awburst),
        .m01_axi_awlock (bridge_axi_awlock),
        .m01_axi_awcache(bridge_axi_awcache),
        .m01_axi_awprot (bridge_axi_awprot),
        .m01_axi_awqos  (bridge_axi_awqos),
        .m01_axi_awregion(),
        .m01_axi_awuser (),
        .m01_axi_awvalid(bridge_axi_awvalid),
        .m01_axi_awready(bridge_axi_awready),
        .m01_axi_wdata  (bridge_axi_wdata),
        .m01_axi_wstrb  (bridge_axi_wstrb),
        .m01_axi_wlast  (bridge_axi_wlast),
        .m01_axi_wuser  (),
        .m01_axi_wvalid (bridge_axi_wvalid),
        .m01_axi_wready (bridge_axi_wready),
        .m01_axi_bid    (bridge_axi_bid),
        .m01_axi_bresp  (bridge_axi_bresp),
        .m01_axi_buser  (1'b0),
        .m01_axi_bvalid (bridge_axi_bvalid),
        .m01_axi_bready (bridge_axi_bready),
        .m01_axi_arid   (bridge_axi_arid),
        .m01_axi_araddr (bridge_axi_araddr),
        .m01_axi_arlen  (bridge_axi_arlen),
        .m01_axi_arsize (bridge_axi_arsize),
        .m01_axi_arburst(bridge_axi_arburst),
        .m01_axi_arlock (bridge_axi_arlock),
        .m01_axi_arcache(bridge_axi_arcache),
        .m01_axi_arprot (bridge_axi_arprot),
        .m01_axi_arqos  (bridge_axi_arqos),
        .m01_axi_arregion(),
        .m01_axi_aruser (),
        .m01_axi_arvalid(bridge_axi_arvalid),
        .m01_axi_arready(bridge_axi_arready),
        .m01_axi_rid    (bridge_axi_rid),
        .m01_axi_rdata  (bridge_axi_rdata),
        .m01_axi_rresp  (bridge_axi_rresp),
        .m01_axi_rlast  (bridge_axi_rlast),
        .m01_axi_ruser  (1'b0),
        .m01_axi_rvalid (bridge_axi_rvalid),
        .m01_axi_rready (bridge_axi_rready)
    );

endmodule
`default_nettype wire
