


//1. Transaction
class fifo_tx extends uvm_sequence_item;

 rand bit wr_en;
 rand bit rd_en;
 rand bit [15:0] data;

 `uvm_object_utils(fifo_tx)

 function new(string name="fifo_tx");
   super.new(name);
 endfunction

endclass

//2. Sequence
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

//3. Sequencer
class fifo_sequencer extends uvm_sequencer #(fifo_tx);
 `uvm_component_utils(fifo_sequencer)

 function new(string name, uvm_component parent);
   super.new(name,parent);
 endfunction

endclass

//4. Driver
class fifo_driver extends uvm_driver #(fifo_tx);

  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  // Get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set");
  endfunction// Get virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set");
  endfunction



  // Drive transactions to DUT
  task run_phase(uvm_phase phase);

    fifo_tx tx;

    forever begin

      // Get transaction from sequencer
      seq_item_port.get_next_item(tx);

      // Drive at clock edge
      @(posedge vif.wr_clk);

      vif.wr_en   <= tx.wr_en;
      vif.wr_data <= tx.data;
      vif.rd_en   <= tx.rd_en;

      // Inform sequencer done
      seq_item_port.item_done();

    end

  endtask

endclass



//5. Monitor
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
    fifo_tx tx;
    fork

      // Thread 1: Monitor Write side (wr_clk domain)
      forever begin
        @(posedge vif.wr_clk);
        if (vif.wr_en && !vif.full) begin
          tx        = fifo_tx::type_id::create("tx");
          tx.wr_en  = 1;
          tx.rd_en  = 0;
          tx.data   = vif.wr_data;
          mon_port.write(tx);
        end
      end

      // Thread 2: Monitor Read side (rd_clk domain)
      // DUT registers rd_data — it appears ONE cycle after rd_en
      forever begin
        @(posedge vif.rd_clk);
        if (vif.rd_en && !vif.empty) begin
          // Wait one more rd_clk edge for registered output
          @(posedge vif.rd_clk);
          tx        = fifo_tx::type_id::create("tx");
          tx.wr_en  = 0;
          tx.rd_en  = 1;
          tx.data   = vif.rd_data;  // Now valid
          mon_port.write(tx);
        end
      end

    join_none
  endtask

endclass




//6. Converge Collector
class fifo_coverage extends uvm_subscriber #(fifo_tx);
  `uvm_component_utils(fifo_coverage)
  fifo_tx tx;
// Covergroup
  covergroup fifo_cg;
    option.per_instance = 1;
    wr_en_cp : coverpoint tx.wr_en;
    rd_en_cp : coverpoint tx.rd_en;
    data_cp  : coverpoint tx.data;

    // Optional cross coverage
    wr_rd_cross : cross wr_en_cp, rd_en_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    fifo_cg = new();
  endfunction

  // This is called when monitor sends data
  function void write(fifo_tx t);
    tx = t;
    fifo_cg.sample();
  endfunction

endclass


//7. Agent
class fifo_agent extends uvm_agent;

  `uvm_component_utils(fifo_agent)

  fifo_driver    driver;
  fifo_sequencer sequencer;
  fifo_monitor   monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  // BUILD PHASE
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Monitor is ALWAYS created
    monitor = fifo_monitor::type_id::create("monitor", this);

    // Driver + Sequencer only in ACTIVE mode
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = fifo_driver::type_id::create("driver", this);
      sequencer = fifo_sequencer::type_id::create("sequencer", this);
    end
  endfunction


  // CONNECT PHASE
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

   // Connect only if ACTIVE
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass


//7. Scoreboard
class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_tx, fifo_scoreboard) item_collected_export;

  bit [15:0] expected_q[$];
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
    end

    if (tx.rd_en && !tx.wr_en) begin
      if (expected_q.size() == 0) begin
        `uvm_error("SCB_FAIL", "Read seen but expected queue is EMPTY (underflow?)")
        fail_count++;
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
    `uvm_info("SCB_RPT", $sformatf("Results: PASS=%0d FAIL=%0d", pass_count, fail_count), UVM_NONE)
    if (expected_q.size() > 0)
      `uvm_warning("SCB_LEAK", $sformatf("%0d items written but never read", expected_q.size()))
    else
      `uvm_info("SCB_CLEAN", "All written data verified.", UVM_NONE)
  endfunction

endclass




//8. Environment
class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)
  fifo_agent      agent;
  fifo_scoreboard sb;
  fifo_coverage   cov;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
      super.build_phase(phase);
    agent = fifo_agent::type_id::create("agent", this);
    sb    = fifo_scoreboard::type_id::create("sb", this);
    cov   = fifo_coverage::type_id::create("cov", this);
  endfunction


  function void connect_phase(uvm_phase phase);
  	super.connect_phase(phase);
    //  Driver↔Sequencer already done inside fifo_agent)
    // Monitor → Scoreboard
   agent.monitor.mon_port.connect(sb.item_collected_export);
    // Monitor → Coverage 
   agent.monitor.mon_port.connect(cov.analysis_export);
  endfunction
endclass



//9. Test
class fifo_test extends uvm_test;

  `uvm_component_utils(fifo_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_sequence seq;
    phase.raise_objection(this);
    seq = fifo_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #500 //drain delay
    phase.drop_objection(this);
  endtask

endclass


static
// 10. Interface 
interface fifo_if (input logic wr_clk, input logic rd_clk);
  logic        wr_rst_n;
  logic        rd_rst_n;
  logic        wr_en;
  logic        rd_en;
  logic [15:0] wr_data;
  logic [15:0] rd_data;
  logic        full;
  logic        empty;
endinterface


//11. Top Testbench
module tb;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Clock generation
  logic wr_clk = 0;
  logic rd_clk = 0;

  always #5 wr_clk = ~wr_clk;  // 100 MHz write clock
  always #7 rd_clk = ~rd_clk;  // ~71 MHz read clock (async!)

  // Interface — clocks passed as ports
  fifo_if vif (.wr_clk(wr_clk), .rd_clk(rd_clk));

  // DUT
  asy_fifo #(.DATA_WIDTH(16), .ADDR_WIDTH(4)) dut (
    .wr_clk   (wr_clk),
    .wr_rst_n (vif.wr_rst_n),
    .wr_en    (vif.wr_en),
    .wr_data  (vif.wr_data),
    .rd_clk   (rd_clk),        
    .rd_rst_n (vif.rd_rst_n),
    .rd_en    (vif.rd_en),
    .rd_data  (vif.rd_data),
    .full     (vif.full),
    .empty    (vif.empty)
  );

  initial begin
    // Assert resets
    vif.wr_rst_n = 0;
    vif.rd_rst_n = 0;
    vif.wr_en    = 0;
    vif.rd_en    = 0;
    vif.wr_data  = 0;

    // Hold reset for 10 cycles
    repeat(10) @(posedge wr_clk);
    vif.wr_rst_n = 1;
    repeat(3)   @(posedge rd_clk);
    vif.rd_rst_n = 1;

    // Pass interface to UVM config DB
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);

    // Run the test
    run_test("fifo_test");
  end

endmodule


