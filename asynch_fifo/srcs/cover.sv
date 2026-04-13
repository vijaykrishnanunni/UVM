
class fifo_coverage extends uvm_subscriber #(fifo_tx);
  `uvm_component_utils(fifo_coverage)

  fifo_tx tx;

  covergroup fifo_cg;
    option.per_instance = 1;
    wr_en_cp : coverpoint tx.wr_en;
    rd_en_cp : coverpoint tx.rd_en;
    data_cp  : coverpoint tx.data;
    wr_rd_cross : cross wr_en_cp, rd_en_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    fifo_cg = new();
  endfunction

  function void write(fifo_tx t);
    tx = t;
    fifo_cg.sample();
  endfunction

endclass
