class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent     agent;
  fifo_scoreboard scoreboard;
  fifo_coverage   coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = fifo_agent::type_id::create("agent", this);
    scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    coverage   = fifo_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.mon_port.connect(scoreboard.item_collected_export);
    agent.monitor.mon_port.connect(coverage.analysis_export);
  endfunction

endclass
