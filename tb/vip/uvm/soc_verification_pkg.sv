
`ifndef SOC_VERIFICATION_PKG_SV
`define SOC_VERIFICATION_PKG_SV

package soc_verification_pkg;

  import uvm_pkg::*;
  import crc32_pkg::*;

  `include "uvm_macros.svh"

  // AXI4-Lite transaction
  `include "agents/axi_lite/axi_lite_transaction.sv"

  // AXI4-Lite agent
  `include "agents/axi_lite/axi_lite_sequencer.sv"
  `include "agents/axi_lite/axi_lite_driver.sv"
  `include "agents/axi_lite/axi_lite_monitor.sv"
  `include "agents/axi_lite/axi_lite_agent.sv"

  // AXI read memory responder
  `include "agents/axi_read/axi_read_memory_model.sv"

  // Environment and scoreboard
  `include "env/crc_scoreboard.sv"
  `include "env/crc_env.sv"

  // Sequences and tests
  `include "sequences/crc_sequence.sv"
  `include "tests/crc_base_test.sv"

endpackage : soc_verification_pkg

`endif

