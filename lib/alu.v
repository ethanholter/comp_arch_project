// ECE:3350 SISC processor project
// arithmetic logic unit

`timescale 1ns/100ps

module alu (clk, rsa, rsb, imm, c_in, alu_op, funct, alu_result, stat, stat_en);

  /*
   *  ARITHMETIC LOGIC UNIT - alu.v
   *  
   *  Inputs:
   *   - clk: system clock.
   *   - rsa (32 bits): Contents of first register read from the register 
   *        file (rf.v), equivalent to Rs in the instruction set architecture.
   *   - rsb (32 bits): Register B from the register file, equivalent to 
   *        Rt in the ISA.
   *   - imm (16 bits): Immediate value, to be taken from the last 16 bits 
   *        of the instruction. This is always sign-extended for use in the
   *        adder.
   *   - alu_op (4 bits): This control allows the control unit to override
   *        the usual function of the ALU to perform specific operations. 
   *        When bit 0 is set to 1, the control unit is telling the ALU that 
   *        the status register is to be updated.
   *        Bits 3:1 specify the operation of the ALU as follows:
   *          000 - The ALU function is Rsa <fc> Rsb;  fc is function code
   *          001 - The ALU function is Rsa <fc> imm;  fc is function code
   *          010 - The ALU function is Rsa + imm.
   *          011 - The ALU function is Rsa - imm.
   *          100 - The ALU function is Rsa + 1.
   *          101 - The ALU function is Rsa - 1.
   *          110 - The ALU function is Rsa.
   *          111 - The ALU function is Rsb.
   *   - funct (4 bits): This control function specifies the operation
   *        the ALU is to perform as follows. 
   *          0000 - none
   *          0001 - Rsa + Rsb
   *          0010 - Rsa - Rsb
   *          0011 - Rsa + Rsb + c_in
   *          0100 - NOT Rsa
   *          0101 - Rsa AND Rsb
   *          0110 - Rsa  OR Rsb
   *          0111 - Rsa XOR Rsb
   *          1000 - ROR Rsa by Rsb
   *          1001 - ROL Rsa by Rsb
   *          1010 - SHR Rsa by Rsb
   *          1011 - SHL Rsa by Rsb
   *          1100 - RRC Rsa by Rsb
   *          1101 - RLC Rsa by Rsb
   *          1110 - ASR Rsa by Rsb
   *          1111 - ASL Rsa by Rsb
   *   - c_in: carry in from the status register
   *
   *  Outputs:
   *   - alu_result (32 bits): This is the output for the entire ALU.
   *     NOTE - alu_result is latched on the positive edge of the clock.
   *   - stat (4 bits): These bits describe the nature of the output of the
   *        adder:
   *        Bit 3 (Carry) - Set to 1 when the addition or subtraction produces
   *           a carry or borrow, respectively. Useful when multiplying numbers.
   *        Bit 2 (oVerflow) - Set to 1 when the adder overflows. Note that 
   *           this is not equivalent to the carry bit, as two negative 
   *           numbers can produce a carry without overflowing.
   *        Bit 1 (Negative) - Set to 1 when the operation 
   *           would result in a negative number.
   *        Bit 0 (Zero) - Set to 1 when the adder output is equal to zero.
   *   - stat_en (4 bits): This controls when the status register should save the
   *        status bits output by the ALU. Each bit corresponds to the bits in
   *        the stat output.  When a bit = 1, the corresponding bit in the 
   *        status register is updated.
   */
  
  input   clk, c_in;
  input   [31:0] rsa;
  input   [31:0] rsb;
  input   [15:0] imm;
  input   [3:0]  alu_op, funct;
  output  [31:0] alu_result;
  output  [3:0]  stat, stat_en;
 
  wire [3:0]  stat;
  reg  [3:0]  sts_upd;
  reg  [32:0] add_out;
  reg  [31:0] log_out;
  reg  [31:0] shf_out;
  reg  [31:0] alu_out;
  reg  [31:0] reg_rot;
  reg  [31:0] alu_result;
  wire [31:0] imm_ext, opb;
  wire [3:0]  stat_en;
  wire        fsb;
  reg         t, ca, cs, ct;
  integer i;

  // function codes
  parameter ADD = 1,  SUB = 2,  ADC = 3,  LNOT = 4, LOR = 5, LAND = 6, LXOR = 7;
  parameter ROR = 8,  ROL = 9,  SHR = 10, SHL = 11, RRC = 12, RLC = 13, ASR = 14, ASL = 15;

  // sign-extend the immediate value
  assign imm_ext = (imm[15] == 1'b1) ? {16'hFFFF, imm} : {16'h0000, imm};
  assign opb = (alu_op[3:1] == 3'b001) ? imm_ext : rsb;

  // adder
  always @ (rsa, opb, imm_ext, c_in, funct, alu_op)
  begin
    add_out = 33'h000000000;
    case (alu_op[3:1])
      3'b000,
      3'b001: begin
        if (funct == ADD)
          add_out = rsa + opb;
        else if (funct == SUB)
          add_out = rsa - opb;
        else if (funct == ADC)
          add_out = rsa + opb + c_in;
        ca = add_out[32];
      end
      3'b010: begin
        add_out = rsa + imm_ext;
        ca = add_out[32];
      end
      3'b011: begin
        add_out = rsa - imm_ext;
        ca = add_out[32];
      end
      3'b100: begin
        add_out = rsa + 32'h00000001;
        ca = add_out[32];
      end
      3'b101: begin
        add_out = rsa - 32'h00000001;
        ca = add_out[32];
      end
      3'b110: begin
        add_out = rsa;
        ca = 1'b0;
      end
      3'b111: begin
        add_out = opb;
        ca = 1'b0;
      end
    endcase       
  end
  
  // logic  
  always @ (rsa, opb, funct) begin
    log_out = 32'h00000000;
    case (funct[1:0])
      2'b00:    log_out = ~rsa;
      2'b01:    log_out = rsa | opb;
      2'b10:    log_out = rsa & opb;
      2'b11:    log_out = rsa ^ opb;
    endcase
  end

  // shifter
  always @ (rsa, opb, c_in, funct) begin
    shf_out = 32'h00000000;
    ct = 1'b0;
    cs = 1'b0;
    case (funct)
      SHR: begin                   // logical shift right
        cs = rsa[0];
        shf_out = rsa >> opb[4:0]; 
      end 
      SHL: begin                   // logical shift left
        cs = rsa[31];
        shf_out = rsa << opb[4:0];  
      end
      ASR: begin                   // arith shift right
        cs = rsa[0];
        shf_out = rsa >>> opb[4:0]; 
      end 
      ASL: begin                   // arith shift left
        cs = rsa[31];
        shf_out = rsa <<< opb[4:0];  
      end
      ROR: begin                   // rotate right
        reg_rot = rsa;
        for (i = 0; i < opb[4:0]; i = i + 1) begin
          t = reg_rot[0];
          reg_rot[30:0] = reg_rot[31:1];
          reg_rot[31] = t;
          ct = t;
        end
        shf_out = reg_rot;
//      cs = c_in;
        cs = ct;
      end  
      ROL: begin                   // rotate left
        reg_rot = rsa;
        for (i = 0; i < opb[4:0]; i = i + 1) begin
          t = reg_rot[31];
          reg_rot[31:1] = reg_rot[30:0];
          reg_rot[0] = t;
          ct = t;
        end
        shf_out = reg_rot;
//      cs = c_in;
        cs = ct;
      end      
      RRC: begin                   // rotate right with carry
        ct = c_in;
        reg_rot = rsa;
        for (i = 0; i < opb[4:0]; i = i + 1) begin
          t = reg_rot[0];
          reg_rot[30:0] = reg_rot[31:1];
          reg_rot[31] = ct;
          ct = t;
        end
        shf_out = reg_rot;
        cs = ct;
      end  
      RLC: begin                   // rotate left with carry
        ct = c_in;
        reg_rot = rsa;
        for (i = 0; i < opb[4:0]; i = i + 1) begin
          t = reg_rot[31];
          reg_rot[31:1] = reg_rot[30:0];
          reg_rot[0] = ct;
          ct = t;
        end
        shf_out = reg_rot;
        cs = ct;
      end
    endcase    
  end
      
  // output mux
  always @ (add_out, log_out, shf_out, funct, alu_op)
  begin
    if ((alu_op[3:1] != 3'b000) && (alu_op[3:1] != 3'b001))
    begin
      alu_out = add_out[31:0];
      sts_upd = 4'b1011;
    end
    else
    begin
      case (funct[3:2])
        2'b00: begin
          alu_out = add_out[31:0];
          sts_upd = 4'b1111;
        end
        2'b01: begin
          alu_out = log_out;
          sts_upd = 4'b0011;
        end
        2'b10: begin
          alu_out = shf_out;
          sts_upd = 4'b0011;
        end
        2'b11: begin
          alu_out = shf_out;
          sts_upd = 4'b1011;
        end
      endcase
    end  
  end    

  always @(posedge clk)
    alu_result <= alu_out;

  // status code generation 
  // 3 = Carry; 2 = oVerflow; 1 = Negative; 0 = Zero
  // Assume signed operands

  assign fsb = (funct == SUB) ? 1'b1 : 1'b0;

  assign stat[3] = (funct[3] == 1'b0) ? ca : cs;
  assign stat[2] = (~(fsb ^ rsa[31] ^ opb[31])) & (fsb ^ opb[31] ^ add_out[31]);
  assign stat[1] = alu_out[31];
  assign stat[0] = ~|alu_out[31:0];

  // status register enable
  assign stat_en = (alu_op[0] == 1'b1) ? sts_upd : 4'b0000;

endmodule
