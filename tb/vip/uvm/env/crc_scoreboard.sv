class crc_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(crc_scoreboard)

  uvm_analysis_imp #(axi_lite_transaction, crc_scoreboard) analysis_export;

  byte unsigned ref_mem[0:65535];

  bit [31:0] src_addr;
  bit [31:0] transfer_length;
  bit [31:0] software_expected_crc;

  bit [31:0] reference_crc;
  bit [31:0] observed_crc;

  int pass_count;
  int fail_count;

  bit computed_crc_checked;
  bit status_checked;

  function new(string name = "crc_scoreboard",
               uvm_component parent = null);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    foreach (ref_mem[i])
      ref_mem[i] = 8'h00;

    // Independent reference data: "123456789"
    ref_mem[0] = 8'h31;
    ref_mem[1] = 8'h32;
    ref_mem[2] = 8'h33;
    ref_mem[3] = 8'h34;
    ref_mem[4] = 8'h35;
    ref_mem[5] = 8'h36;
    ref_mem[6] = 8'h37;
    ref_mem[7] = 8'h38;
    ref_mem[8] = 8'h39;

    src_addr             = 0;
    transfer_length      = 0;
    software_expected_crc = 0;

    pass_count = 0;
    fail_count = 0;

    computed_crc_checked = 0;
    status_checked = 0;
  endfunction

  function automatic bit [31:0] calculate_crc(
      input bit [31:0] start_addr,
      input bit [31:0] length
  );

    bit [31:0] crc;
    bit [7:0] data_byte;
    integer i;
    integer j;
    integer index;

    crc = 32'hFFFFFFFF;

    for (i = 0; i < length; i++) begin

      index = start_addr + i;

      if (index >= 0 && index < 65536) begin
        data_byte = ref_mem[index];

        crc = crc ^ data_byte;

        for (j = 0; j < 8; j++) begin
          if (crc[0])
            crc = (crc >> 1) ^ 32'hEDB88320;
          else
            crc = crc >> 1;
        end
      end
      else begin
        `uvm_error("SCOREBOARD", "Reference memory address out of range")
      end

    end

    return crc ^ 32'hFFFFFFFF;

  endfunction

  function void write(axi_lite_transaction tr);

    if (tr.operation == axi_lite_transaction::AXI_WRITE) begin

      case (tr.address)

        32'h00000008:
          src_addr = tr.data;

        32'h00000010:
          transfer_length = tr.data;

        32'h00000014:
          software_expected_crc = tr.data;

        default: begin
        end

      endcase

    end

    else begin

      case (tr.address)

        // STATUS register
        32'h00000004: begin

          if (tr.read_data[1]) begin

            reference_crc = calculate_crc(
                src_addr, transfer_length
            );

            status_checked = 1;

            if (tr.read_data[2] &&
                software_expected_crc == reference_crc) begin

              `uvm_info("SCOREBOARD",
                        "STATUS PASS bit is correct",
                        UVM_MEDIUM)

            end
            else if (tr.read_data[3] &&
                     software_expected_crc != reference_crc) begin

              `uvm_info("SCOREBOARD",
                        "STATUS FAIL bit is correct",
                        UVM_MEDIUM)

            end
            else begin

              `uvm_error("SCOREBOARD",
                         "STATUS PASS/FAIL does not match reference CRC")

              fail_count++;

            end

          end

        end

        // COMPUTED_CRC register
        32'h00000018: begin

          observed_crc = tr.read_data;

          reference_crc = calculate_crc(
              src_addr, transfer_length
          );

          computed_crc_checked = 1;

          if (observed_crc == reference_crc) begin

            pass_count++;

            `uvm_info("SCOREBOARD",
                      $sformatf(
                        "CRC MATCH: DUT=0x%08h REF=0x%08h",
                        observed_crc, reference_crc
                      ),
                      UVM_MEDIUM)

          end
          else begin

            fail_count++;

            `uvm_error("SCOREBOARD",
                       $sformatf(
                         "CRC MISMATCH: DUT=0x%08h REF=0x%08h",
                         observed_crc, reference_crc
                       ))

          end

        end

        default: begin
        end

      endcase

    end

  endfunction

  function void report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info("SCOREBOARD",
              $sformatf("CRC checks passed: %0d", pass_count),
              UVM_LOW)

    `uvm_info("SCOREBOARD",
              $sformatf("CRC checks failed: %0d", fail_count),
              UVM_LOW)

    if (!computed_crc_checked)
      `uvm_error("SCOREBOARD", "Computed CRC was never checked")

    if (!status_checked)
      `uvm_error("SCOREBOARD", "DONE status was never checked")

    if (fail_count != 0)
      `uvm_error("SCOREBOARD", "Scoreboard detected failures")

  endfunction

endclass
