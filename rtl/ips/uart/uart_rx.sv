// =============================================================================
// File        : uart_rx.sv
// Project     : WaveGuard SoC — VeeR EL2 Honours Project
// Description : UART Receiver with 8-bit streaming handshake output to DMA.
//
// Interface:
//   - uart_rx (serial input pin)
//   - uart_rx_data [7:0] (streaming byte out)
//   - uart_rx_valid (valid strobe)
//   - uart_rx_ready (backpressure handshake from DMA)
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module uart_rx #(
    parameter int CLKS_PER_BIT = 16 // Default clock cycles per bit (e.g. 16 for simulation)
)(
    input  wire       clk,
    input  wire       rst_n,

    // Serial Input
    input  wire       uart_rx,

    // Streaming Handshake to DMA
    output reg  [7:0] m_axis_tdata,
    output reg        m_axis_tvalid,
    input  wire       m_axis_tready
);

    // Synchronise RX input to clock domain
    reg rx_sync1;
    reg rx_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // UART FSM States
    localparam [2:0]
        S_IDLE  = 3'b000,
        S_START = 3'b001,
        S_DATA  = 3'b010,
        S_STOP  = 3'b011,
        S_OUT   = 3'b100;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_byte;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            clk_count     <= 16'h0;
            bit_index     <= 3'h0;
            rx_byte       <= 8'h0;
            m_axis_tdata  <= 8'h0;
            m_axis_tvalid <= 1'b0;
        end else begin
            // Clear valid once accepted
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end

            case (state)
                S_IDLE: begin
                    clk_count <= 16'h0;
                    bit_index <= 3'h0;
                    if (rx_sync2 == 1'b0) begin // Start bit detected (falling edge)
                        state <= S_START;
                    end
                end

                S_START: begin
                    // Sample at mid-point of start bit
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx_sync2 == 1'b0) begin
                            clk_count <= 16'h0;
                            state     <= S_DATA;
                        end else begin
                            state     <= S_IDLE; // False start bit
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                S_DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count          <= 16'h0;
                        rx_byte[bit_index] <= rx_sync2;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 3'h0;
                            state     <= S_STOP;
                        end
                    end
                end

                S_STOP: begin
                    // Wait for stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'h0;
                        state     <= S_OUT;
                    end
                end

                S_OUT: begin
                    // Wait until consumer is ready or set valid
                    if (!m_axis_tvalid || m_axis_tready) begin
                        m_axis_tdata  <= rx_byte;
                        m_axis_tvalid <= 1'b1;
                        state         <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
