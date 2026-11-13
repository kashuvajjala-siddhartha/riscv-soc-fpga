
class axi_lite_transaction extends uvm_sequence_item;

  typedef enum bit {
    AXI_WRITE = 1'b0,
    AXI_READ  = 1'b1
  } operation_t;

  rand operation_t operation;
  rand bit [31:0] address;
  rand bit [31:0] data;
  rand bit [3:0]  strobe;

  bit [1:0] response;
  bit [31:0] read_data;

  `uvm_object_utils_begin(axi_lite_transaction)
    `uvm_field_enum(operation_t, operation, UVM_ALL_ON)
    `uvm_field_int(address,   UVM_ALL_ON)
    `uvm_field_int(data,      UVM_ALL_ON)
    `uvm_field_int(strobe,    UVM_ALL_ON)
    `uvm_field_int(response,  UVM_ALL_ON)
    `uvm_field_int(read_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axi_lite_transaction");
    super.new(name);
    strobe = 4'b1111;
  endfunction

  constraint aligned_address {
    address[1:0] == 2'b00;
  }

endclass

