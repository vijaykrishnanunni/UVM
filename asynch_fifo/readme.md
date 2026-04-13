
---

# Async FIFO Verification using UVM

## Overview

This project verifies an Asynchronous FIFO using UVM in SystemVerilog. The FIFO operates with separate read and write clocks, making it a CDC-based design.

## Objectives

* Verify read/write functionality
* Check full and empty conditions
* Validate data integrity and ordering
* Test simultaneous read/write
* Detect overflow and underflow

## UVM Components

* Transaction (fifo_tx)
* Sequence & Sequencer
* Driver
* Monitor
* Agent
* Scoreboard (queue-based reference model)
* Coverage
* Environment & Test

## Verification Approach

* Driver applies stimulus from sequences
* Monitor captures DUT activity
* Scoreboard compares DUT output with expected queue behavior
* Coverage tracks key FIFO scenarios

## Test Scenarios

* Basic read/write
* FIFO full and empty
* Simultaneous read/write
* Overflow and underflow
* Random traffic

## Run (Example VCS)

```
vcs -sverilog -ntb_opts uvm rtl/async_fifo.v tb/*.sv -o simv
./simv +UVM_TESTNAME=fifo_test
```

## Pass Criteria

* No mismatches in scoreboard
* No UVM errors
* Coverage goals met

---
