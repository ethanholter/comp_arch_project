// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps

module sisc (clk, rst_f);

    // inputs
    input clk, rst_f;

    // outputs

    // wires
    wire [31:0] rsa, rsb;
	 wire [31:0] alu_result;
	 wire [31:0] write_data;
	 wire [31:0] instr;
	 wire [31:0] read_data;
	 
    wire [3:0] stat_in, stat_out, stat_en; 									//status register i/o
    wire rf_we, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load; 	// ctrl module outputs
	 wire [3:0] alu_op;
	 
	 wire [15:0] br_addr;
	 wire [15:0] pc_out;
	 wire [15:0] imm;
	 
	 wire pc_inc;
	 
	 pc PC(clk, br_addr, pc_sel, pc_write, pc_rst, pc_out);
	 ir u9(clk, ir_load, read_data, instr);
	 im IM(pc_out, read_data);
	 br BR(pc_out, instr[15:0], br_sel, br_addr);
	 
    ctrl u1 (clk, rst_f, instr[31:28], instr[27:24], stat_out, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load);
	 rf u2(clk, instr[19:16], instr[15:12], instr[23:20], write_data, rf_we, rsa, rsb);
	 alu u3 (clk, rsa, rsb, instr[15:0], stat_out[0], alu_op, instr[27:24], alu_result, stat_in, stat_en);
	 mux32 u5(alu_result, 0, wb_sel, write_data);
	 statreg u6(clk, stat_in, stat_en, stat_out);

	 
    initial begin
		$monitor($time,,"IR=%h RSA=%h RSB=%h | R1=%h R2=%h R3=%h R4=%h R5=%h | ALU_OP=%b FUNC=%b STAT=%b | WB_SEL=%h RF_WE=%h WD=%h", 
			instr,
			rsa,   
			rsb,
			u2.ram_array[1],
			u2.ram_array[2],
			u2.ram_array[3],
			u2.ram_array[4],
			u2.ram_array[5],
			alu_op,
			instr[27:24],
			stat_out,
			wb_sel,
			rf_we,
			write_data
		);
	 end
	 always @(instr) begin
		$display("[%h]: %h", pc_out, instr);
	 end
endmodule
