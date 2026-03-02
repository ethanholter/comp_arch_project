// ECE:3350 SISC processor project
// test bench for sisc processor, part 1

`timescale 1ns/100ps  

module sisc_tb;

  parameter    tclk = 10.0;    
  reg          clk;
  reg          rst_f;
  reg [31:0]   ir;

  // component instantiation
  // "uut" stands for "Unit Under Test"
 
  sisc uut ( clk, rst_f, ir);

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


  initial
  begin
    // To test all of the arithmetic instructions:
        ir = 32'h00000000; //NOP
    #85 ir = 32'h21100001; //ADI  R1 <- R0 + (0x0000)0001
    #50 ir = 32'h11211000; //ADD  R2 <- R1 + R1
    #50 ir = 32'h1B322000; //SHL  R3 <- R2 << [R2]
    #50 ir = 32'h12412000; //SUB  R4 <- R1 - R2
    #50 ir = 32'h1A443000; //SHR  R4 <- R4 >> [R3]
    #50 ir = 32'h17234000; //XOR  R2 <- R3 ^ R4
    #50 ir = 32'h14220000; //NOT  R2 <- ~R2
    #50 ir = 32'h19421000; //ROL  R4 <- R2 <.< [R1]
    #50 ir = 32'h15524000; //OR   R5 <- R2 | R4
    #50 ir = 32'h16324000; //AND  R3 <- R2 & R4
    #50 ir = 32'h00000000; //NOP

	/*
	 * At this point, registers should be as follows:
	 *   R1: 00000001		R4: FE000011
	 *   R2: FF000008		R5: FF000019
	 *   R3: FE000000		R0, R6-R15: 00000000
	 */

    // To test status code generation:
    #50 ir = 32'h21100001; //ADI  R1 <- R0 + (0x0000)0001 (STAT: 0000)
    #50 ir = 32'h12211000; //SUB  R2 <- R1 - R1           (STAT: 0001)
    #50 ir = 32'h12201000; //SUB  R2 <- R0 - R1           (STAT: 1010)
    #50 ir = 32'h18311000; //ROR  R3 <- R1 >> [R1]
    #50 ir = 32'h11423000; //ADD  R4 <- R2 + R3           (STAT: 1100)
    #50 ir = 32'hF0000000; //HALT

  end
 
endmodule
