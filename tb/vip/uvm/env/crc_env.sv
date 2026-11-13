
class crc_env extends uvm_env;

  `uvm_component_utils(crc_env)

  axi_lite_agent       axi_agent;
  axi_read_memory_model memory_model;
  crc_scoreboard       scoreboard;

  function new(string name = "crc_env",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    axi_agent = axi_lite_agent::type_id::create(
                  "axi_agent", this);

    memory_model = axi_read_memory_model::type_id::create(
                     "memory_model", this);

    scoreboard = crc_scoreboard::type_id::create(
                   "scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    axi_agent.monitor.ap.connect(
      scoreboard.analysis_export
    );
  endfunction

endclass

