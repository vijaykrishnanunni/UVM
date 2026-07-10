class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_env      env;
  fifo_sequence seq;

  function new(string name = "fifo_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    seq = fifo_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (env.scoreboard.fail_count == 0)
      `uvm_info("TEST_DONE", "*** TEST PASSED ***", UVM_NONE)
    else
      `uvm_error("TEST_DONE", "*** TEST FAILED ***")
  endfunction

endclass
