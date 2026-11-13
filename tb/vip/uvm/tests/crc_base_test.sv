
class crc_base_test extends uvm_test;

  `uvm_component_utils(crc_base_test)

  crc_env env;

  function new(string name = "crc_base_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = crc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);

    crc_sequence seq;

    phase.raise_objection(this);

    `uvm_info("CRC_TEST",
      "Starting CRC UVM test", UVM_LOW)

    seq = crc_sequence::type_id::create("seq");
    seq.start(env.axi_agent.sequencer);

    `uvm_info("CRC_TEST",
      "CRC UVM test sequence completed", UVM_LOW)

    #100ns;
    phase.drop_objection(this);

  endtask

endclass

