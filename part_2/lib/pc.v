// ECE:3350 SISC processor project
// program counter

`timescale 1ns/100ps

module pc (clk, br_addr, pc_sel, pc_write, pc_rst, pc_out);

  /*
   *  PROGRAM COUNTER - pc.v
   *
   *  Inputs:
   *   - clk: System clock; positive edge active
   *   - br_addr (16 bits): The branch address computed by the br module.
   *   - pc_sel: This control bit tells the pc module whether to save the branch
   *        address (pc_sel = 1) or PC+1 (pc_sel = 0) to the program counter.
   *   - pc_write: When this control bit changes to 1, the selected value (either
   *        the branch address or PC+1) is saved to pc_out and held there until
   *        the next time pc_en is set to 1.
   *   - pc_rst: This resets the program counter to 0x0000 when set to 1.
   *
   *  Outputs:
   *   - pc_out (16 bits): This is the current value of the program counter, to
   *        be used in the instruction memory (im.v) module.
   *
   */

  input         clk;
  input  [15:0] br_addr;
  input         pc_sel;
  input         pc_write;
  input         pc_rst;
  output [15:0] pc_out;

  reg    [15:0] pc_in;
  reg    [15:0] pc_out;
 
  // program counter latch
  always @(posedge clk)
  begin
    if (pc_rst == 1'b1)
      pc_out <= 16'h0000;
    else
      if (pc_write == 1'b1)
        pc_out <= pc_in;
  end
  
  always @(br_addr, pc_out, pc_sel)
  begin
    if (pc_sel == 1'b0)
      pc_in <= pc_out + 1;
    else
      pc_in <= br_addr;
  end

endmodule
