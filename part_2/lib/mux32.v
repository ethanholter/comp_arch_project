// ECE:3350 SISC processor project
// 32-bit mux

`timescale 1ns/100ps

module mux32 (in_a, in_b, sel, out);

  /*
   *  32-BIT MULTIPLEXER - mux32.v
   *
   *  Inputs:
   *   - in_a (32 bits): First input to multiplexer. Selected when sel = 0.
   *   - in_b (32 bits): Second input. Selected when sel = 1.
   *   - sel: Selects which input propagates to output.
   *
   *  Outputs:
   *   - out (32 bits): Multiplexer output.
   *
   */

  input  [31:0] in_a;
  input  [31:0] in_b;
  input         sel;
  output [31:0] out;

  reg   [31:0] outreg;
   
  always @ (in_a, in_b, sel)
  begin
    if (sel == 1'b0)
      outreg = in_a;
    else
      outreg = in_b;
  end

  assign out = outreg;

endmodule
