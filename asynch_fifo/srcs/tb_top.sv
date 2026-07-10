`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fifo_pkg::*;

  bit wr_clk, rd_clk;

  always #5  wr_clk = ~wr_clk;
  always #7  rd_clk = ~rd_clk;

  fifo_if intf (.wr_clk(wr_clk), .rd_clk(rd_clk));

  // DUT instance - connect to your async_fifo RTL
  async_fifo dut (
    .wr_clk  (intf.wr_clk),
    .wr_rst_n(intf.wr_rst_n),
    .wr_en   (intf.wr_en),
    .wr_data (intf.wr_data),
    .full    (intf.full),
    .rd_clk  (intf.rd_clk),
    .rd_rst_n(intf.rd_rst_n),
    .rd_en   (intf.rd_en),
    .rd_data (intf.rd_data),
    .empty   (intf.empty)
  );

  initial begin
    intf.wr_rst_n = 0;
    intf.rd_rst_n = 0;
    #20;
    intf.wr_rst_n = 1;
    intf.rd_rst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", intf);
    run_test("fifo_test");
  end

endmodule
