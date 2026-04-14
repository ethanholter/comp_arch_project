// ECE:3350 SISC processor project
// test bench for sisc processor, parts 2 - 4

`timescale 1ns/100ps  

module sisc_tb;

  parameter    tclk = 10.0;    
  reg          clk;
  reg          rst_f;

  // component instantiation
  // "uut" stands for "Unit Under Test"
  // sisc uut (.clk   (clk),
  //          .rst_f (rst_f),
  //          .ir    (ir));
 
  sisc uut ( clk, rst_f);

  // clock driver
  initial
  begin
    clk = 0;    
  end
	
  always
  begin
    #(tclk/2.0);
    clk = ~clk;
  end
 
  // reset control
  initial 
  begin
    rst_f = 0;
    // wait for 20 ns;
    #20; 
    rst_f = 1;
  end

endmodule
