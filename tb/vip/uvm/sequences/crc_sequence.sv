
class crc_sequence extends uvm_sequence #(axi_lite_transaction);

  `uvm_object_utils(crc_sequence)

  function new(string name = "crc_sequence");
    super.new(name);
  endfunction

  task automatic axi_write(
    input bit [31:0] addr,
    input bit [31:0] data
  );

    axi_lite_transaction tr;

    tr = axi_lite_transaction::type_id::create("write_tr");

    start_item(tr);
    tr.operation = axi_lite_transaction::AXI_WRITE;
    tr.address   = addr;
    tr.data      = data;
    tr.strobe    = 4'b1111;
    finish_item(tr);

  endtask

  task automatic axi_read(
    input bit [31:0] addr,
    output bit [31:0] data
  );

    axi_lite_transaction tr;

    tr = axi_lite_transaction::type_id::create("read_tr");

    start_item(tr);
    tr.operation = axi_lite_transaction::AXI_READ;
    tr.address   = addr;
    finish_item(tr);

    data = tr.read_data;

  endtask

  task body();

    bit [31:0] result;
    int poll_count;

    `uvm_info("CRC_SEQUENCE",
      "Starting CRC-32 standard test", UVM_LOW)

    // Configure source address
    axi_write(32'h08, 32'h00000000);

    // Configure source length: 9 bytes
    axi_write(32'h10, 32'd9);

    // Expected CRC for ASCII "123456789"
    axi_write(32'h14, 32'hCBF43926);

    // Start CRC operation
    axi_write(32'h00, 32'h00000001);

    // Poll STATUS.DONE
    poll_count = 0;

    do begin
      axi_read(32'h04, result);
      poll_count++;

      if (poll_count > 100)
        `uvm_fatal("CRC_TIMEOUT", "CRC operation timed out")

    end while (!result[1]);

    // Read computed CRC
    axi_read(32'h18, result);

    if (result == 32'hCBF43926)
      `uvm_info("CRC_SEQUENCE",
        $sformatf("PASS: computed CRC = %08h", result), UVM_LOW)
    else
      `uvm_error("CRC_SEQUENCE",
        $sformatf("FAIL: expected CB F4 39 26, got %08h", result))

  endtask

endclass

