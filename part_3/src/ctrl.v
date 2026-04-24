// ECE:3350 SISC computer project
// finite state machine

`timescale 1ns/100ps

module ctrl (clk, rst_f, opcode, mm, stat, rf_we, alu_op, wb_sel, br_sel, pc_rst, pc_write, pc_sel, ir_load, rb_sel, mm_sel, dm_we);

/* Declare the ports listed above as inputs or outputs.  Note that this is
only the signals for part 1.  You will be adding signals for parts 2,
    2, and 4. */

   //TODO rb_sel mm_sel dm_we

   input clk, rst_f;
   input [3:0] opcode, mm, stat;
   output reg rf_we, wb_sel;
   output reg [3:0] alu_op;
   output reg br_sel, pc_rst, pc_write, pc_sel, ir_load;
   output reg rb_sel, mm_sel, dm_we;

   // state parameter declarations

   parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;

   // opcode parameter declarations

   parameter NOOP = 0, REG_OP = 1, REG_IM = 2, SWAP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7;
   parameter JPA = 8, JPR = 9, LOD = 10, STR = 11, CALL = 12, RET = 13, HLT = 15;

   // addressing modes

   parameter AM_IMM = 8;

   // state register and next state signal

   reg [2:0]  present_state, next_state;

   // initial procedure to initialize the present state to 'start0'.

   initial
       present_state = start0;

   /* Procedure that progresses the fsm to the next state on the positive edge of 
   the clock, OR resets the state to 'start1' on the negative edge of rst_f. 
       Notice that the computer is reset when rst_f is low, not high. */

      always @(posedge clk, negedge rst_f)
      begin
          if (rst_f == 1'b0)
              present_state <= start1;
          else
              present_state <= next_state;
      end

      /* The following combinational procedure determines the next state of the fsm. */

      always @(present_state, rst_f)
      begin
          case(present_state)
              start0:
                  next_state = start1;
              start1:
                  if (rst_f == 1'b0) begin
                      next_state = start1;
                      pc_rst = 1;
                  end
                  else begin
                      pc_rst = 0;
                      next_state = fetch;
                  end
                  fetch:
                      next_state = decode;
                  decode:
                      next_state = execute;
                  execute:
                      next_state = mem;
                  mem:
                      next_state = writeback;
                  writeback:
                      next_state = fetch;
                  default:
                      next_state = start1;
              endcase
          end

          always @(present_state, opcode)
          begin
              /* TODO: Generate combinational signals based on the FSM states and inputs. For Parts 2, 3 and 4 you will
              add the new control signals here. */

             // inputs:   opcode, mm, stat
             // outputs:  rf_we, wb_sel, alu_op 

             case(present_state)

                 fetch: begin
                     rf_we <= 0;
                     ir_load <= 1;
                     pc_write <= 1;

                     wb_sel <= 0; // for now this always stays off
                     rb_sel <= 0;
                 end

                 decode: begin
                     ir_load <= 0;
                     pc_write <= 0;

                     case(opcode)
                         BRA: begin
                             br_sel <= 1;
                             pc_sel <= (mm & stat) != 0;
                             pc_write <= (mm & stat) != 0;
                         end
                         BRR: begin
                             br_sel <= 0;
                             pc_sel <= (mm & stat) != 0;
                             pc_write <= (mm & stat) != 0;
                         end
                         BNE: begin
                             br_sel <= 1;
                             pc_sel <= (mm & stat) == 0;
                             pc_write <= (mm & stat) == 0;
                         end
                         BNR: begin	
                         br_sel <= 0;
                         pc_sel <= (mm & stat) == 0;
                         pc_write <= (mm & stat) == 0;
                     end
                     default: begin end
                 endcase
             end

             execute: begin
                 pc_write <= 0;
                 br_sel <= 0;
                 pc_sel <= 0;

                 case(opcode)
                     REG_OP: begin
                         alu_op <= 4'b0001;
                     end
                     REG_IM: begin
                         alu_op <= 4'b0011;
                     end
                     default: begin 
                     alu_op <= 4'b0000;
                 end
             endcase
         end

         mem: begin
             case(opcode)
                 REG_OP: begin
                     alu_op <= 4'b0000;
                 end
                 REG_IM: begin
                     alu_op <= 4'b0010;
                 end
                 default: begin end
             endcase

         end

         writeback: begin
             alu_op <= 4'b0000;
             case(opcode)
                 REG_OP: begin
                     rf_we <= 1;
                 end
                 REG_IM: begin
                     rf_we <= 1;
                 end
                 default: begin
                     rf_we <= 0;
                 end
             endcase
         end
     endcase
 end

 // Halt on HLT instruction

 always @ (opcode)
 begin
     if (opcode == HLT)
     begin 
     #5 $display ("Halt."); //Delay 5 ns so $monitor will print the halt instruction
     $stop;
 end
  end


  endmodule
