
---

# UVM (Universal Verification Methodology)

## Overview

UVM is a SystemVerilog-based methodology used for building reusable, scalable, and structured verification environments for digital designs.

## Key Concepts

* **Transaction-based verification**
* **Reusable components (agents, environments)**
* **Separation of stimulus, driving, and checking**
* **Configuration using `uvm_config_db`**
* **Phases for controlled simulation flow**

## UVM Components

* **Sequence Item** – represents a transaction
* **Sequence** – generates stimulus
* **Sequencer** – controls transaction flow
* **Driver** – drives DUT signals
* **Monitor** – observes DUT activity
* **Agent** – groups driver, sequencer, monitor
* **Scoreboard** – checks correctness (reference model)
* **Coverage** – tracks verification completeness
* **Environment** – connects all components
* **Test** – configures and runs the verification

## UVM Phases

* **build_phase** – create components
* **connect_phase** – connect TLM ports
* **run_phase** – apply stimulus (time-based)
* **report_phase** – print results

## Simulation Flow

1. Test is selected using `run_test()`
2. Sequences generate transactions
3. Driver sends stimulus to DUT
4. Monitor captures outputs
5. Scoreboard checks expected vs actual
6. Coverage collects metrics

## Benefits

* High reusability
* Scalable for complex SoCs
* Standardized industry methodology
* Supports constrained random verification

## Usage (Example VCS)

```id="r40jrd"
vcs -sverilog -ntb_opts uvm tb_top.sv -o simv
./simv +UVM_TESTNAME=base_test
```

## Applications

* ASIC/FPGA verification
* Protocol verification (AXI, UART, etc.)
* System-level verification

---

