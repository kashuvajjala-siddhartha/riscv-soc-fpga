
class axi_lite_driver extends uvm_driver #(axi_lite_transaction);

  `uvm_component_utils(axi_lite_driver)

  virtual soc_crc_if vif;

  function new(string name = "axi_lite_driver",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual soc_crc_if)::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF",
                 "AXI-Lite driver: virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);

    axi_lite_transaction tr;

    // Wait until reset is released
    wait (vif.rst_n === 1'b1);

    drive_idle();

    forever begin

      seq_item_port.get_next_item(tr);

      if (tr.operation == axi_lite_transaction::AXI_WRITE)
        drive_write(tr);
      else
        drive_read(tr);

      seq_item_port.item_done();

    end

  endtask

  task drive_idle();

    vif.s_axi_awaddr  = '0;
    vif.s_axi_awprot  = '0;
    vif.s_axi_awvalid = 1'b0;

    vif.s_axi_wdata   = '0;
    vif.s_axi_wstrb   = '0;
    vif.s_axi_wvalid  = 1'b0;

    vif.s_axi_bready  = 1'b0;

    vif.s_axi_araddr  = '0;
    vif.s_axi_arprot  = '0;
    vif.s_axi_arvalid = 1'b0;

    vif.s_axi_rready  = 1'b0;

  endtask

  task drive_write(axi_lite_transaction tr);

    bit aw_done;
    bit w_done;

    aw_done = 1'b0;
    w_done  = 1'b0;

    @(negedge vif.clk);

    vif.s_axi_awaddr  = tr.address;
    vif.s_axi_awprot  = 3'b000;
    vif.s_axi_awvalid = 1'b1;

    vif.s_axi_wdata   = tr.data;
    vif.s_axi_wstrb   = tr.strobe;
    vif.s_axi_wvalid  = 1'b1;

    while (!aw_done || !w_done) begin

      @(posedge vif.clk);

      if (vif.s_axi_awvalid && vif.s_axi_awready)
        aw_done = 1'b1;

      if (vif.s_axi_wvalid && vif.s_axi_wready)
        w_done = 1'b1;

      @(negedge vif.clk);

      if (aw_done)
        vif.s_axi_awvalid = 1'b0;

      if (w_done)
        vif.s_axi_wvalid = 1'b0;

    end

    vif.s_axi_bready = 1'b1;

    do begin
      @(posedge vif.clk);
    end while (!vif.s_axi_bvalid);

    tr.response = vif.s_axi_bresp;

    @(negedge vif.clk);
    vif.s_axi_bready = 1'b0;

  endtask

  task drive_read(axi_lite_transaction tr);

    @(negedge vif.clk);

    vif.s_axi_araddr  = tr.address;
    vif.s_axi_arprot  = 3'b000;
    vif.s_axi_arvalid = 1'b1;

    do begin
      @(posedge vif.clk);
    end while (!vif.s_axi_arready);

    @(negedge vif.clk);

    vif.s_axi_arvalid = 1'b0;
    vif.s_axi_rready  = 1'b1;

    do begin
      @(posedge vif.clk);
    end while (!vif.s_axi_rvalid);

    tr.read_data = vif.s_axi_rdata;
    tr.response  = vif.s_axi_rresp;

    @(negedge vif.clk);
    vif.s_axi_rready = 1'b0;

  endtask

endclass

