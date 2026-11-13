// =============================================================================
// File        : axi4_ram.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : 64-bit AXI4 Slave Memory with burst support and hex preload.
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module axi4_ram #(
    parameter int DATA_WIDTH = 64,
    parameter int ADDR_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,
    parameter int ID_WIDTH   = 8,
    parameter int MEM_SIZE   = 65536, // 64 KB default memory (8192 x 64-bit words)
    parameter     INIT_FILE  = ""
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // Write Address Channel
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // Write Response Channel
    output reg  [ID_WIDTH-1:0]    s_axi_bid,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // Read Address Channel
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // Read Data Channel
    output reg  [ID_WIDTH-1:0]    s_axi_rid,
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rlast,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    localparam WORDS = MEM_SIZE / STRB_WIDTH;
    reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

    // Optional Hex Preload
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Write logic
    reg [ADDR_WIDTH-1:0] w_addr;
    reg [7:0]            w_len;
    reg [ID_WIDTH-1:0]   w_id;
    reg                  w_active;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= '0;
            w_active      <= 1'b0;
            w_len         <= 8'h0;
        end else begin
            if (~w_active) begin
                s_axi_awready <= 1'b1;
                if (s_axi_awvalid && s_axi_awready) begin
                    w_addr        <= s_axi_awaddr;
                    w_len         <= s_axi_awlen;
                    w_id          <= s_axi_awid;
                    w_active      <= 1'b1;
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b1;
                end
            end else begin
                if (s_axi_wvalid && s_axi_wready) begin
                    // Write with byte strobes
                    for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                        if (s_axi_wstrb[i]) begin
                            mem[w_addr[15:3]][i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
                        end
                    end

                    w_addr <= w_addr + 8; // Increment by 8 bytes (64 bits)

                    if (w_len == 8'h0 || s_axi_wlast) begin
                        w_active     <= 1'b0;
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bid    <= w_id;
                        s_axi_bresp  <= 2'b00; // OKAY
                    end else begin
                        w_len <= w_len - 1'b1;
                    end
                end
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read logic
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [7:0]            r_len;
    reg [ID_WIDTH-1:0]   r_id;
    reg                  r_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            s_axi_rdata   <= '0;
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= '0;
            r_active      <= 1'b0;
            r_len         <= 8'h0;
        end else begin
            if (~r_active) begin
                s_axi_arready <= 1'b1;
                if (s_axi_arvalid && s_axi_arready) begin
                    r_addr        <= s_axi_araddr;
                    r_len         <= s_axi_arlen;
                    r_id          <= s_axi_arid;
                    r_active      <= 1'b1;
                    s_axi_arready <= 1'b0;

                    s_axi_rvalid  <= 1'b1;
                    s_axi_rid     <= s_axi_arid;
                    s_axi_rdata   <= mem[s_axi_araddr[15:3]];
                    s_axi_rresp   <= 2'b00;
                    s_axi_rlast   <= (s_axi_arlen == 8'h0);
                end
            end else begin
                if (s_axi_rvalid && s_axi_rready) begin
                    if (r_len == 8'h0) begin
                        r_active     <= 1'b0;
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                    end else begin
                        r_addr       <= r_addr + 8;
                        r_len        <= r_len - 1'b1;
                        s_axi_rdata  <= mem[(r_addr + 8) >> 3];
                        s_axi_rvalid <= 1'b1;
                        s_axi_rlast  <= (r_len == 8'd1);
                    end
                end
            end
        end
    end

endmodule
`default_nettype wire
