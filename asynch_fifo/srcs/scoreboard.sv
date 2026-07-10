
class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_tx, fifo_scoreboard) item_collected_export;

  bit [15:0] expected_q[$];   
  bit [15:0] pending_rd_q[$];
  int pass_count, fail_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_export = new("item_collected_export", this);
  endfunction

  virtual function void write(fifo_tx tx);
    bit [15:0] expected_data;


    if (tx.wr_en && !tx.rd_en) begin
      expected_q.push_back(tx.data);
      `uvm_info("SCB_WR", $sformatf("Write: %0h | Queue depth: %0d",
                tx.data, expected_q.size()), UVM_HIGH)

     
      while (pending_rd_q.size() > 0 && expected_q.size() > 0) begin
        bit [15:0] pending_data = pending_rd_q.pop_front();
        expected_data           = expected_q.pop_front();
        if (expected_data === pending_data) begin
          `uvm_info("SCB_PASS", $sformatf("MATCH (pending) exp=%0h got=%0h",
                    expected_data, pending_data), UVM_MEDIUM)
          pass_count++;
        end else begin
          `uvm_error("SCB_FAIL", $sformatf("MISMATCH (pending) exp=%0h got=%0h",
                     expected_data, pending_data))
          fail_count++;
        end
      end
    end

  
    if (tx.rd_en && !tx.wr_en) begin
      if (expected_q.size() == 0) begin

        
        `uvm_info("SCB_CDC", $sformatf(
          "Read %0h arrived before write (CDC skew) — holding in pending queue",
          tx.data), UVM_MEDIUM)
        pending_rd_q.push_back(tx.data);
      end else begin
        expected_data = expected_q.pop_front();
        if (expected_data === tx.data) begin
          `uvm_info("SCB_PASS", $sformatf("MATCH  exp=%0h got=%0h",
                    expected_data, tx.data), UVM_MEDIUM)
          pass_count++;
        end else begin
          `uvm_error("SCB_FAIL", $sformatf("MISMATCH exp=%0h got=%0h",
                     expected_data, tx.data))
          fail_count++;
        end
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
   
    if (pending_rd_q.size() > 0) begin
      `uvm_error("SCB_PENDING", $sformatf(
        "%0d read(s) in pending queue were never matched by a write — real underflow",
        pending_rd_q.size()))
      fail_count += pending_rd_q.size();
    end
    `uvm_info("SCB_RPT", $sformatf("Results: PASS=%0d FAIL=%0d",
              pass_count, fail_count), UVM_NONE)
    if (expected_q.size() > 0)
      `uvm_warning("SCB_LEAK", $sformatf(
        "%0d items written but never read", expected_q.size()))
    else
      `uvm_info("SCB_CLEAN", "All written data verified.", UVM_NONE)
  endfunction

endclass
