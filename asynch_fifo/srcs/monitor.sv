
class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;
  uvm_analysis_port #(fifo_tx) mon_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set");
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_write_side();
      monitor_read_side();
    join_none
  endtask


  task monitor_write_side();
    fifo_tx tx;
    forever begin
      @(posedge vif.wr_clk);
      #1; // wait for NBA region — DUT registered outputs now stable

      if (vif.wr_en && !vif.full) begin
        tx        = fifo_tx::type_id::create("tx");
        tx.wr_en  = 1'b1;
        tx.rd_en  = 1'b0;
        tx.data   = vif.wr_data;
        `uvm_info("MON_WR", $sformatf("Write captured: data=%0h", tx.data), UVM_HIGH)
        mon_port.write(tx);
      end
    end
  endtask

 
  task monitor_read_side();
    fifo_tx tx;
    logic   sampled_rd_en;
    logic   sampled_empty;

    forever begin
     
      @(posedge vif.rd_clk);
      #1; 
      sampled_rd_en = vif.rd_en;
      sampled_empty = vif.empty;

      if (sampled_rd_en && !sampled_empty) begin

       
        @(posedge vif.rd_clk);
        #1;

      
        tx        = fifo_tx::type_id::create("tx");
        tx.wr_en  = 1'b0;
        tx.rd_en  = 1'b1;         
        tx.data   = vif.rd_data;  
        `uvm_info("MON_RD", $sformatf("Read  captured: data=%0h", tx.data), UVM_HIGH)
        mon_port.write(tx);
      end
    end
  endtask

endclass
