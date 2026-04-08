class fifo_tx extends uvm_sequence_item;

 rand bit wr_en;
 rand bit rd_en;
 rand bit [15:0] data;

 `uvm_object_utils(fifo_tx)

 function new(string name="fifo_tx");
   super.new(name);
 endfunction

endclass
