// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps

module sisc (clk, rst_f);

// inputs
input clk, rst_f;

// wires
wire [31:0] rsa;
wire [31:0] rsb;
wire [31:0] alu_result;
wire [31:0] write_data;
wire [31:0] instr;
wire [31:0] read_data;
wire [31:0] dm_read_data;

wire [15:0] br_addr;
wire [15:0] pc_out;
wire [15:0] imm;
wire [15:0] mem_addr;

wire [3:0] stat_in;
wire [3:0] stat_out;
wire [3:0] stat_en; 				//status register i/o
wire [3:0] alu_op;
wire [3:0] regb;

wire rf_we;
wire wb_sel;
wire br_sel;
wire pc_rst;
wire pc_write;
wire pc_sel;
wire ir_load; 	// ctrl module outputs
wire pc_inc;
wire rb_sel;
wire mm_sel;
wire dm_we;

// part 1
ctrl    u1 (clk, rst_f, instr[31:28], instr[27:24], stat_out, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load, rb_sel, mm_sel, dm_we);
rf      u2(clk, instr[19:16], regb, instr[23:20], write_data, rf_we, rsa, rsb);
alu     u3 (clk, rsa, rsb, instr[15:0], stat_out[3], alu_op, instr[27:24], alu_result, stat_in, stat_en);
mux32   u5(alu_result, dm_read_data, wb_sel, write_data);
statreg u6(clk, stat_in, stat_en, stat_out);

// part 2
br      u7(pc_out, instr[15:0], br_sel, br_addr);
im      u8(pc_out, read_data);
ir      u9(clk, ir_load, read_data, instr);
pc      u10(clk, br_addr, pc_sel, pc_write, pc_rst, pc_out);

// part 3
dm      u11(mem_addr, mem_addr, rsb, dm_we, dm_read_data);
mux16   u12(alu_result[15:0], instr[15:0], mm_sel, mem_addr);
mux4    u13(instr[15:12], instr[23:20], rb_sel, regb);



initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, sisc); // Replaces top_module_name with your testbench module name
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

    if (instr == 32'hF0000000) begin : mem_dump
        integer i;
        $display("Mem dump:");
        for (i = 0; i < 8; i = i + 1)
            $display("  M[%0d] = %0d", i, $signed(u11.ram_array[i]));
    end
end
endmodule
