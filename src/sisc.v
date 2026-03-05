// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps

module sisc (clk, rst_f, instr);

    // inputs
    input clk, rst_f;
    input [31:0] instr;

    // outputs

    // wires
    wire [31:0] rsa, rsb;                  // ALU input registers
    wire [3:0] stat_in, stat_out, stat_en; //status register i/o
    wire rf_we, wb_sel;                    // ctrl module outputs
	 wire [3:0] alu_op;
	 wire [31:0] alu_result;
	 wire write_data;

    ctrl CTRL(clk, rst_f, instr[31:28]/*opcode*/, instr[27:24]/*mm*/, stat_out, rf_we, alu_op, wb_sel);
    statreg STATREG(clk, stat_in, stat_en, stat_out);
    alu ALU(clk, rsa, rsb, instr[15:0]/*imm*/, stat_out[0], alu_op, instr[11:0]/*funct*/, alu_result, stat_in, stat_en);
	 rf RF(clk, instr[19:16]/*rega*/, instr[15:12]/*regb*/, instr[23:20]/*write_reg*/, write_data/*TODO*/, rf_we, rsa, rsb);
	 mux32 MUX(0, alu_result, wb_sel, write_data);
    initial 
   // RF rf (clk, read_rega, read_regb, write_reg, write_data, rf_we, rsa, rsb);
   // MUX mux32 (in_a, in_b, sel, out);

    // put a $monitor statement here.
    $monitor ("[$monitor] rsa=0x%0h rsb=0x%0h", rsa, rsb);


endmodule
