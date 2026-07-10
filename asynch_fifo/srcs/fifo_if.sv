interface fifo_if (input bit wr_clk, input bit rd_clk);
  logic         wr_rst_n;
  logic         rd_rst_n;
  logic         wr_en;
  logic [15:0]  wr_data;
  logic         full;
  logic         rd_en;
  logic [15:0]  rd_data;
  logic         empty;
endinterface
