class fifo_sequence extends uvm_sequence #(fifo_tx);
   `uvm_object_utils(fifo_sequence)
  function new(string name="fifo_sequence");
     super.new(name);
   endfunction
    
   task body();
     fifo_tx tx;
     repeat(20) begin
          tx = fifo_tx::type_id::create("tx");
               start_item(tx);
               assert(tx.randomize());
               finish_item(tx);
          end
   endtask
endclass
