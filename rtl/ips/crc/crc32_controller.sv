// =============================================================================
// File        : crc32_controller.sv
// Project     : CRC-32 IP — VeeR EL2 SoC
// Author      : Honours Project 1602-23-735-045
// Created     : 2026-11-07
// Description : CRC-32 controller — top-level control state machine.
//
//   Coordinates between:
//     - AXI4-Lite slave register interface (receives start/config/clear)
//     - AXI4 read master (requests memory read operations)
//     - CRC-32 byte core (receives byte stream, accumulates CRC)
//
//   State machine:
//     IDLE    : Wait for start pulse from register interface.
//     RUNNING : Assert start to AXI read master.  Stream bytes from read
//               master into CRC byte core.  Track completion and errors.
//     DONE    : Latch computed CRC, compare to expected, set status.
//               Assert interrupt if enabled.
//     ERROR   : Memory read error occurred; set error status.
//
//   Zero-length transfers:
//     If LENGTH register is 0, DONE is asserted immediately with the
//     CRC of an empty message = 0xFFFFFFFF ^ 0xFFFFFFFF = 0x00000000.
//     PASS is asserted only if EXPECTED_CRC == 0x00000000.
//
//   Busy guard:
//     A new START while BUSY is silently ignored.
//
//   Software reset (SW_RESET):
//     Returns all state to IDLE, clears status and CRC registers.
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module crc32_controller
  import crc32_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // --------------------------------------------------------------------------
  // Interface from AXI4-Lite register slave
  // --------------------------------------------------------------------------
  input  logic        reg_start_i,
  input  logic        reg_sw_reset_i,
  input  logic        reg_ie_i,
  input  logic [31:0] reg_src_addr_i,
  input  logic [31:0] reg_length_i,
  input  logic [31:0] reg_expected_i,
  input  logic        reg_irq_clear_i,

  // --------------------------------------------------------------------------
  // Status outputs to AXI4-Lite register slave
  // --------------------------------------------------------------------------
  output logic [4:0]  reg_status_o,      // [4]=ERROR [3]=FAIL [2]=PASS [1]=DONE [0]=BUSY
  output logic [31:0] reg_computed_o,
  output logic        reg_irq_status_o,

  // --------------------------------------------------------------------------
  // Interface to AXI4 read master
  // --------------------------------------------------------------------------
  output logic        rm_start_o,
  output logic [31:0] rm_base_addr_o,
  output logic [31:0] rm_byte_count_o,
  input  logic        rm_done_i,
  input  logic        rm_error_i,

  // --------------------------------------------------------------------------
  // Byte stream from AXI4 read master to CRC core
  // (controller routes this and provides CRC core control signals)
  // --------------------------------------------------------------------------
  input  logic [7:0]  byte_data_i,
  input  logic        byte_valid_i,
  output logic        byte_ready_o,

  // --------------------------------------------------------------------------
  // Interface to CRC-32 byte core
  // --------------------------------------------------------------------------
  output logic        crc_init_o,    // initialise CRC register
  output logic        crc_valid_o,   // data byte valid
  output logic [7:0]  crc_data_o,    // data byte to CRC core
  input  logic [31:0] crc_result_i,  // current CRC output (with final XOR)

  // --------------------------------------------------------------------------
  // Interrupt output
  // --------------------------------------------------------------------------
  output logic        irq_o
);

  // --------------------------------------------------------------------------
  // Controller state machine
  // --------------------------------------------------------------------------
  crc_state_t state, next_state;

  // --------------------------------------------------------------------------
  // Internal registers
  // --------------------------------------------------------------------------
  logic [31:0] computed_crc_reg;
  logic        irq_status_reg;
  logic [4:0]  status_reg;      // {ERROR, FAIL, PASS, DONE, BUSY}
  logic        rm_start_issued; // set once rm_start_o fires; cleared on IDLE entry

  // --------------------------------------------------------------------------
  // Sequential state update
  // --------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n || reg_sw_reset_i) begin
      state <= CRC_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // --------------------------------------------------------------------------
  // Next-state logic
  // --------------------------------------------------------------------------
  always_comb begin
    next_state = state;
    case (state)
      CRC_IDLE: begin
        if (reg_start_i)
          next_state = CRC_FETCH;
      end

      CRC_FETCH: begin
        // rm_start_o is asserted for one cycle, then we wait for data.
        // Gate rm_done_i and rm_error_i on rm_start_issued so that a stale
        // sticky done_o from a previous run cannot cause a premature CRC_DONE
        // on the first clock of CRC_FETCH before the read master has cleared
        // its done_r latch.  rm_start_issued becomes 1 on the second clock of
        // CRC_FETCH, by which time the read master has already cleared done_r.
        if (rm_error_i && rm_start_issued)
          next_state = CRC_ERROR;
        else if (rm_done_i && rm_start_issued)
          next_state = CRC_DONE;
        else if (byte_valid_i)
          next_state = CRC_PROCESS;
      end

      CRC_PROCESS: begin
        if (rm_error_i)
          next_state = CRC_ERROR;
        else if (rm_done_i && !byte_valid_i)
          next_state = CRC_DONE;
        // Stay in PROCESS while bytes are flowing or until done
      end

      CRC_DONE: begin
        // Hold for one cycle for result latching, then return to IDLE
        next_state = CRC_IDLE;
      end

      CRC_ERROR: begin
        next_state = CRC_IDLE;
      end

      default: next_state = CRC_IDLE;
    endcase
  end

  // --------------------------------------------------------------------------
  // Datapath: CRC core control, status, interrupt
  // --------------------------------------------------------------------------

  always_ff @(posedge clk) begin
    if (!rst_n || reg_sw_reset_i) begin
      status_reg      <= 5'b0;
      computed_crc_reg<= '0;
      irq_status_reg  <= 1'b0;
      rm_start_issued <= 1'b0;
    end else begin

      // Clear interrupts via W1C
      if (reg_irq_clear_i)
        irq_status_reg <= 1'b0;

      case (state)

        CRC_IDLE: begin
          rm_start_issued <= 1'b0;
          if (reg_start_i) begin
            // Clear previous status, assert BUSY
            status_reg <= 5'b0_0_0_0_1; // BUSY=1
          end
        end

        CRC_FETCH: begin
          // Issue rm_start once
          if (!rm_start_issued) begin
            rm_start_issued <= 1'b1;
          end
        end

        CRC_PROCESS: begin
          // Nothing to latch here — CRC core is running
        end

        CRC_DONE: begin
          computed_crc_reg <= crc_result_i;
          begin
            logic pass_flag;
            logic fail_flag;
            pass_flag = (crc_result_i == reg_expected_i);
            fail_flag = !pass_flag;
            // {ERROR=0, FAIL, PASS, DONE=1, BUSY=0}
            status_reg <= {1'b0, fail_flag, pass_flag, 1'b1, 1'b0};
          end
          // Assert interrupt if enabled
          if (reg_ie_i) begin
            irq_status_reg <= 1'b1;
          end
        end

        CRC_ERROR: begin
          computed_crc_reg <= crc_result_i;
          // {ERROR=1, FAIL=0, PASS=0, DONE=1, BUSY=0}
          status_reg <= 5'b1_0_0_1_0;
          if (reg_ie_i) begin
            irq_status_reg <= 1'b1;
          end
        end

        default: ;
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // CRC core control outputs
  // --------------------------------------------------------------------------

  // Initialise the CRC core when START is issued
  assign crc_init_o  = reg_start_i;

  // Pass byte stream from read master to CRC core
  // Only accept bytes when in FETCH or PROCESS state
  assign byte_ready_o = (state == CRC_FETCH || state == CRC_PROCESS);
  assign crc_valid_o  = byte_valid_i && byte_ready_o;
  assign crc_data_o   = byte_data_i;

  // --------------------------------------------------------------------------
  // Read master control outputs
  // --------------------------------------------------------------------------
  // Start the read master one cycle after entering FETCH state
  // (rm_start is a one-cycle pulse, issued when rm_start_issued goes false→true)
  assign rm_start_o      = (state == CRC_FETCH) && !rm_start_issued;
  assign rm_base_addr_o  = reg_src_addr_i;
  assign rm_byte_count_o = reg_length_i;

  // --------------------------------------------------------------------------
  // Status and interrupt outputs
  // --------------------------------------------------------------------------
  assign reg_status_o     = status_reg;
  assign reg_computed_o   = computed_crc_reg;
  assign reg_irq_status_o = irq_status_reg;
  assign irq_o            = irq_status_reg && reg_ie_i;

endmodule : crc32_controller

`default_nettype wire
