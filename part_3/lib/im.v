// ECE:3350 SISC processor project
// instruction memory

`timescale 1ns/100ps

module im (read_addr, read_data);

  /*
   *  INSTRUCTION MEMORY - im.v
   *
   *  Inputs:
   *   - read_addr (16 bits): The address of the instruction to read.
   *
   *  Outputs:
   *   - read_data (32 bits): The instruction specified by address read_addr.
   *
   */

  input  [15:0] read_addr;
  output [31:0] read_data;
  
  reg    [31:0] ram_array [65535:0];
  reg    [31:0] read_data;

  // load program
  initial begin : prog_load
    $readmemh("imem.data",ram_array);
  end
 
  // read process is sensitive to read address.
  // address is [15:0] because ram_array is word addressable, //not byte addressable.
  always @(read_addr)
  begin
    read_data <= ram_array[read_addr[15:0]];
  end
  
endmodule
