class axi_read_memory_model extends uvm_component;

  `uvm_component_utils(axi_read_memory_model)

  virtual soc_crc_if vif;

  byte unsigned mem[0:65535];

  function new(string name = "axi_read_memory_model",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual soc_crc_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("MEM", "Virtual interface not found")

    foreach (mem[i])
      mem[i] = 8'h00;

    // Reference test data: "123456789"
    mem[0] = 8'h31;
    mem[1] = 8'h32;
    mem[2] = 8'h33;
    mem[3] = 8'h34;
    mem[4] = 8'h35;
    mem[5] = 8'h36;
    mem[6] = 8'h37;
    mem[7] = 8'h38;
    mem[8] = 8'h39;
  endfunction

  task run_phase(uvm_phase phase);

    int unsigned addr;
    int unsigned beats;
    logic [7:0] burst_id;
    logic [63:0] word_data;
    int beat;
    int lane;
    int unsigned mem_addr;

    vif.m_axi_arready = 1'b0;
    vif.m_axi_rvalid  = 1'b0;
    vif.m_axi_rdata   = 64'h0;
    vif.m_axi_rid     = 8'h0;
    vif.m_axi_rresp   = 2'b00;
    vif.m_axi_rlast   = 1'b0;

    forever begin

      // Accept one read address.
      @(negedge vif.clk);
      vif.m_axi_arready = 1'b1;

      do begin
        @(posedge vif.clk);
      end while (!(vif.m_axi_arvalid && vif.m_axi_arready));

      // Capture address information at the handshake.
      addr     = vif.m_axi_araddr;
      beats    = int'(vif.m_axi_arlen) + 1;
      burst_id = vif.m_axi_arid;

      @(negedge vif.clk);
      vif.m_axi_arready = 1'b0;

      // Return all beats in this burst.
      for (beat = 0; beat < beats; beat++) begin

        word_data = 64'h0;

        for (lane = 0; lane < 8; lane++) begin
          mem_addr = addr + (beat * 8) + lane;

          if (mem_addr < 65536)
            word_data[lane*8 +: 8] = mem[mem_addr];
        end

        // Present data and hold it until accepted.
        vif.m_axi_rid    = burst_id;
        vif.m_axi_rdata  = word_data;
        vif.m_axi_rresp  = 2'b00;
        vif.m_axi_rlast  = (beat == beats - 1);
        vif.m_axi_rvalid = 1'b1;

        do begin
          @(posedge vif.clk);
        end while (!(vif.m_axi_rvalid && vif.m_axi_rready));

        @(negedge vif.clk);
        vif.m_axi_rvalid = 1'b0;
        vif.m_axi_rlast  = 1'b0;

      end
    end

  endtask

endclass
