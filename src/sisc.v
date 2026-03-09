// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps

module sisc (clk, rst_f, instr);

    // inputs
    input clk, 	rst_f;
    input [31:0] instr;

    // outputs

    // wires
    wire [31:0] rsa, rsb;                  // ALU input registers
    wire [3:0] stat_in, stat_out, stat_en; //status register i/o
    wire rf_we, wb_sel;                    // ctrl module outputs
	 wire [3:0] alu_op;
	 wire [31:0] alu_result;
	 wire [31:0] write_data;

    ctrl CTRL(clk, rst_f, instr[31:28]/*opcode*/, instr[27:24]/*MFF*/, stat_out, rf_we, alu_op, wb_sel);
    statreg STATREG(clk, stat_in, stat_en, stat_out);
    alu ALU(clk, rsa, rsb, instr[15:0]/*imm*/, stat_out[0], alu_op, instr[27:24]/*MFF*/, alu_result, stat_in, stat_en);
	 mux32 MUX(0, alu_result, wb_sel, write_data);
	 rf RF(clk, instr[19:16]/*rega*/, instr[15:12]/*regb*/, instr[23:20]/*write_reg*/, write_data, rf_we, rsa, rsb);
	 
    initial begin
		$monitor($time,,"IR=%h RSA=%h RSB=%h | R1=%h R2=%h R3=%h R4=%h R5=%h | ALU_OP=%b FUNC=%b STAT=%b | WB_SEL=%h RF_WE=%h WD=%h", 
			instr,
			rsa,
			rsb,
			RF.ram_array[1],
			RF.ram_array[2],
			RF.ram_array[3],
			RF.ram_array[4],
			RF.ram_array[5],
			alu_op,
			instr[27:24],
			stat_out,
			wb_sel,
			rf_we,
			write_data
		);
	 end
endmodule
