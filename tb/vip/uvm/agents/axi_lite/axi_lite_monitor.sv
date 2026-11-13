class axi_lite_monitor extends uvm_monitor;

  `uvm_component_utils(axi_lite_monitor)

  virtual soc_crc_if vif;

  uvm_analysis_port #(axi_lite_transaction) ap;

  bit [31:0] aw_queue[$];
  bit [31:0] wdata_queue[$];
  bit [3:0]  wstrb_queue[$];
  bit [31:0] ar_queue[$];

  function new(string name = "axi_lite_monitor",
               uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual soc_crc_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_aw();
      monitor_w();
      monitor_b();
      monitor_ar();
      monitor_r();
    join
  endtask

  task monitor_aw();
    forever begin
      @(posedge vif.clk);
      if (vif.s_axi_awvalid && vif.s_axi_awready)
        aw_queue.push_back(vif.s_axi_awaddr);
    end
  endtask

  task monitor_w();
    forever begin
      @(posedge vif.clk);
      if (vif.s_axi_wvalid && vif.s_axi_wready) begin
        wdata_queue.push_back(vif.s_axi_wdata);
        wstrb_queue.push_back(vif.s_axi_wstrb);
      end
    end
  endtask

  task monitor_b();
    axi_lite_transaction tr;

    forever begin
      @(posedge vif.clk);

      if (vif.s_axi_bvalid && vif.s_axi_bready) begin

        if (aw_queue.size() == 0 ||
            wdata_queue.size() == 0 ||
            wstrb_queue.size() == 0) begin
          `uvm_error("MON", "Write response without matching AW/W")
        end
        else begin
          tr = axi_lite_transaction::type_id::create("write_tr");

          tr.operation = axi_lite_transaction::AXI_WRITE;
          tr.address   = aw_queue.pop_front();
          tr.data      = wdata_queue.pop_front();
          tr.strobe    = wstrb_queue.pop_front();
          tr.response  = vif.s_axi_bresp;

          ap.write(tr);
        end
      end
    end
  endtask

  task monitor_ar();
    forever begin
      @(posedge vif.clk);
      if (vif.s_axi_arvalid && vif.s_axi_arready)
        ar_queue.push_back(vif.s_axi_araddr);
    end
  endtask

  task monitor_r();
    axi_lite_transaction tr;

    forever begin
      @(posedge vif.clk);

      if (vif.s_axi_rvalid && vif.s_axi_rready) begin

        if (ar_queue.size() == 0) begin
          `uvm_error("MON", "Read response without matching AR")
        end
        else begin
          tr = axi_lite_transaction::type_id::create("read_tr");

          tr.operation = axi_lite_transaction::AXI_READ;
          tr.address   = ar_queue.pop_front();
          tr.read_data = vif.s_axi_rdata;
          tr.response  = vif.s_axi_rresp;

          ap.write(tr);
        end
      end
    end
  endtask

endclass
