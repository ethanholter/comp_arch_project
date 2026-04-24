// ECE:3350 SISC processor project
// 16-bit mux

`timescale 1ns/100ps

module mux16 (in_a, in_b, sel, out);

  /*
   *  16-BIT MULTIPLEXER - mux16.v
   *
   *  Inputs:
   *   - in_a (16 bits): First input to the multiplexer. Chosen when sel = 0.
   *   - in_b (16 bits): Second input to the multiplexer. Chosen when sel = 1.
   *   - sel: Controls which input is seen at the output.
   *
   *  Outputs:
   *   - out: Output from the multiplexer.
   *
   */

  input  [15:0] in_a;
  input  [15:0] in_b;
  input         sel;
  output [15:0] out;

  reg   [15:0] out;
   
  always @ (in_a, in_b, sel)
  begin
    if (sel == 1'b0)
      out <= in_a;
    else
      out <= in_b;
  end

endmodule 
