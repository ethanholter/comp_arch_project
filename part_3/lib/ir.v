// ECE:3350 SISC processor project
// instruction register

`timescale 1ns/100ps

module ir (clk, ir_load, read_data, instr);

  /*
   *  INSTRUCTION REGISTER - ir.v
   *
   *  Inputs:
   *   - clk: System clock; positive edge active
   *   - ir_load: if ir_load is = 1, the IR is loaded with read_data
   *   - read_data (32 bits): the 32 bit instruction from instruction memory
   *
   *  Outputs:
   *   - instr (32 bits): the 32 bit saved instruction
   *
   */
  
  input         clk;
  input         ir_load;
  input  [31:0] read_data;
  output [31:0] instr;

  wire          clk;
  wire          ir_load;
  wire   [31:0] read_data;
  reg    [31:0] instr;
 
  // instruction register
  
  initial
    instr <= 32'h00000000;

  always @(posedge clk)
    if (ir_load == 1'b1)
      instr <= read_data;
  

endmodule
