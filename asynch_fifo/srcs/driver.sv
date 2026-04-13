class fifo_driver extends uvm_driver #(fifo_tx);
 
  `uvm_component_utils(fifo_driver)
 
  virtual fifo_if vif;
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
 
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set");
  endfunction
 
  // Drive transactions to DUT
  task run_phase(uvm_phase phase);
    fifo_tx tx;
    forever begin
      seq_item_port.get_next_item(tx);
      @(posedge vif.wr_clk);
      vif.wr_en   <= tx.wr_en;
      vif.wr_data <= tx.data;
      vif.rd_en   <= tx.rd_en;
      seq_item_port.item_done();
    end
  endtask
 
endclass
 
