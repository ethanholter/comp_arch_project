// ============================================================================
// ECE:3350 SISC Processor - Checkpoint Testbench
// ============================================================================
//
// This testbench checks register values at intermediate points during
// execution to help you identify WHICH part of your design is failing.
//
// It monitors the PC and checks values at known instruction addresses:
//   - After addr 0x0B: Part 1 Section 1 complete
//   - After addr 0x11: Part 1 Section 2 complete
//   - After addr 0x1D: Part 2 (branches) complete
//   - After addr 0x25: Part 3 (load/store) complete = HLT
//
// ============================================================================

`timescale 1ns/100ps

module sisc_checkpoint_tb;

  parameter TCLK = 10.0;
  reg clk, rst_f;
  integer total_pass, total_fail;

  sisc uut (.clk(clk), .rst_f(rst_f));

  initial clk = 0;
  always #(TCLK/2.0) clk = ~clk;

  initial begin
    rst_f = 0;
    #20;
    rst_f = 1;
  end

  initial begin
    #100000;
    $display("  TIMEOUT: Simulation exceeded 100us.");
    $finish;
  end

  // ---- Scorekeeping ----
  integer pass_count, fail_count;

  task check_val;
    input [255:0] name;
    input [31:0]  actual;
    input [31:0]  expected;
    begin
      if (actual === expected) begin
        $display("    [PASS]  %-8s = %h", name, actual);
        pass_count = pass_count + 1;
        total_pass = total_pass + 1;
      end else begin
        $display("    [FAIL]  %-8s = %h  (expected %h)", name, actual, expected);
        fail_count = fail_count + 1;
        total_fail = total_fail + 1;
      end
    end
  endtask

  // ---- Track which checkpoints we've hit ----
  reg cp1_done, cp2_done, cp3_done, cp4_done;

  initial begin
    total_pass = 0;
    total_fail = 0;
    cp1_done = 0;
    cp2_done = 0;
    cp3_done = 0;
    cp4_done = 0;
  end

  // ---- Monitor PC for checkpoint addresses ----
  // We check at the writeback of the NOP/HLT instructions that follow each section.
  // The PC value when the instruction at address X is being fetched = X.
  // We watch for the instruction register holding the checkpoint instruction.

  always @(posedge clk) begin
    // Checkpoint 1: After Part 1 Section 1
    // Instruction at 0x0B is a NOP. By the time the NEXT instruction (0x0C) is in
    // fetch, R1-R5 should have their Part1-Section1 values.
    // We detect this by watching for IR = the instruction at 0x0C (ADI R1,R0,#1 = 0x21100001)
    // and PC = 0x000D (just fetched 0x0C, about to move on)
    if (!cp1_done && uut.u9.instr == 32'h21100001 && uut.u10.pc_out == 16'h000D) begin
      cp1_done = 1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 1: Part 1 Section 1 (after addr 0x0B) ----");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'hFF000008);
      check_val("R3", uut.u2.ram_array[3],  32'hFE000000);
      check_val("R4", uut.u2.ram_array[4],  32'hFE000011);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Section 1: %0d/%0d passed", pass_count, pass_count + fail_count);
    end

    // Checkpoint 2: After Part 1 Section 2
    // Instruction at 0x11 is a NOP. Next is 0x12 (ADD R4,R0,R0 = 0x11400000)
    if (!cp2_done && uut.u9.instr == 32'h11400000 && uut.u10.pc_out == 16'h0013) begin
      cp2_done = 1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 2: Part 1 Section 2 (after addr 0x11) ----");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'hFFFFFFFF);
      check_val("R3", uut.u2.ram_array[3],  32'h80000000);
      check_val("R4", uut.u2.ram_array[4],  32'h7FFFFFFF);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Section 2: %0d/%0d passed", pass_count, pass_count + fail_count);
    end

    // Checkpoint 3: After Part 2 (branches)
    // Instruction at 0x1D is NOP. Next is 0x1E (ADI R1,R0,#1 = 0x21100001) with PC=0x001F
    if (!cp3_done && uut.u9.instr == 32'h21100001 && uut.u10.pc_out == 16'h001F) begin
      cp3_done = 1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 3: Part 2 Branches (after addr 0x1D) ----");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'h00000000);
      check_val("R3", uut.u2.ram_array[3],  32'h00000000);
      check_val("R4", uut.u2.ram_array[4],  32'h00000006);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      $display("    Branches: %0d/%0d passed", pass_count, pass_count + fail_count);
    end
  end

  // Checkpoint 4: HLT = final state
  reg hlt_done;
  initial hlt_done = 0;

  always @(uut.u9.instr) begin
    if (!hlt_done && uut.u9.instr[31:28] == 4'hF && $time > 100) begin
      hlt_done = 1;
      #1;
      pass_count = 0;
      fail_count = 0;
      $display("");
      $display("  ---- CHECKPOINT 4: Part 3 Load/Store (HLT) ----");
      check_val("R1", uut.u2.ram_array[1],  32'h00000001);
      check_val("R2", uut.u2.ram_array[2],  32'hFF000019);
      check_val("R3", uut.u2.ram_array[3],  32'h00000006);
      check_val("R4", uut.u2.ram_array[4],  32'h00000006);
      check_val("R5", uut.u2.ram_array[5],  32'hFF000019);
      check_val("M[8]", uut.u11.ram_array[8], 32'h00000006);
      check_val("M[9]", uut.u11.ram_array[9], 32'hFF000019);
      $display("    Load/Store: %0d/%0d passed", pass_count, pass_count + fail_count);

      $display("");
      $display("============================================================");
      $display("  OVERALL: %0d / %0d checks passed", total_pass, total_pass + total_fail);
      if (total_fail == 0)
        $display("  STATUS: ALL CHECKPOINTS PASSED");
      else
        $display("  STATUS: %0d CHECKS FAILED", total_fail);
      $display("============================================================");
      $display("");
    end
  end

endmodule
