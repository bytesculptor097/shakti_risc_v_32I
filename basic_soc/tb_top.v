
module tb_top;
  reg clk = 0;
  reg rst_n = 0;

  wire uart_tx;
  wire [2:0] dbg_led;

  always #41 clk = ~clk; // ~12 MHz

  mkeclass_axi4 dut (
    .clk(clk),
    .rst_n(rst_n),
    .uart_tx(uart_tx),
    .dbg_led(dbg_led)
  );

  initial begin
    $dumpfile("wave.vcd"); // (optional) for waveform
    $dumpvars(0, tb_top);  // (optional) dump all signals

    #100;
    rst_n = 1;

    #1000000;
    $finish;
  end
endmodule
