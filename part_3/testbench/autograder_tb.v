// ============================================================================
// ECE:3350 SISC Processor - Autograder Testbench
// ============================================================================
//
// USAGE:
//   This testbench automatically checks register and memory values after
//   your SISC processor executes the imem.data program. It prints PASS/FAIL
//   for each checked value and a summary score at the end.
//
// REQUIREMENTS:
//   Your sisc.v module must use these instance names (matching the project spec):
//     ctrl     u1       rf       u2       alu      u3
//     mux32    u5       statreg  u6       br       u7
//     im       u8       ir       u9       pc       u10
//     dm       u11      mux4     u12      mux16    u13
//
//   Your sisc module port list should be: sisc(clk, rst_f)
//   (or sisc(clk, rst_f, ir) with ir left unconnected by this testbench)
//
// RUNNING (Icarus Verilog):
//   iverilog -o autograder_tb autograder_tb.v sisc.v ctrl.v rf.v alu.v \
//            mux32.v statreg.v br.v im.v ir.v pc.v dm.v mux4.v mux16.v
//   vvp autograder_tb
//
// RUNNING (ModelSim):
//   vlog *.v
//   vsim -c sisc_autograder_tb -do "run -all; quit"
//
// ============================================================================

`timescale 1ns/100ps

module sisc_autograder_tb;

  // ---- Clock and Reset ----
  parameter TCLK = 10.0;
  reg clk, rst_f;

  // ---- Scorekeeping ----
  integer pass_count, fail_count;

  // ---- DUT Instantiation ----
  // Uses named ports so it works whether sisc has 2 or 3 ports.
  // If your sisc still has 'ir' as a port, it is left unconnected here
  // (the internal ir module drives it). You may see a warning - this is OK.
  //
  // NOTE: If you get a compilation error about port mismatch, your sisc.v
  // module may need the 'ir' port removed from the port list since it is now
  // driven internally by the ir module (u9). The port list should be:
  //   module sisc (clk, rst_f);
  sisc uut (.clk(clk), .rst_f(rst_f));

  // ---- Clock Generator ----
  initial clk = 0;
  always #(TCLK/2.0) clk = ~clk;

  // ---- Reset Sequence ----
  initial begin
    rst_f = 0;
    #20;
    rst_f = 1;
  end

  // ---- Timeout Watchdog ----
  initial begin
    #100000;
    $display("");
    $display("============================================================");
    $display("  TIMEOUT: Simulation exceeded 100us without reaching HLT.");
    $display("  This likely means your processor is stuck in an infinite");
    $display("  loop or the PC is not advancing correctly.");
    $display("============================================================");
    $finish;
  end

  // ---- Optional Verbose Trace ----
  // Uncomment the line below to see register state after every writeback.
  // This prints: Time, PC, IR, R1-R5, ALU_OP at each clock edge during
  // the writeback state, giving you a per-instruction trace.
  //
  // `define AUTOGRADER_VERBOSE
  `ifdef AUTOGRADER_VERBOSE
  always @(posedge clk) begin
    if ($time > 50) begin
      // Print header once
      if ($time < 60)
        $display("  TIME     PC    IR        R1        R2        R3        R4        R5       ALU_OP");
      // Print state (ctrl state visible via alu_op activity)
      $display("  %6t  %h  %h  %h  %h  %h  %h  %h  %b",
        $time, uut.u10.pc_out, uut.u9.instr,
        uut.u2.ram_array[1], uut.u2.ram_array[2], uut.u2.ram_array[3],
        uut.u2.ram_array[4], uut.u2.ram_array[5], uut.u1.alu_op);
    end
  end
  `endif

  // ---- HLT Detection and Value Checking ----
  //
  // The ctrl module detects HLT with: always @(opcode) if(opcode==HLT) #5 $stop;
  // We detect HLT by watching the instruction register output.
  // Our #1 delay runs checks BEFORE ctrl's #5 $stop fires.

  reg checking_done;
  initial checking_done = 0;

  always @(uut.u9.instr) begin
    if (!checking_done && uut.u9.instr[31:28] == 4'hF && $time > 100) begin
      checking_done = 1;
      #1; // settle time; runs before ctrl's #5 $stop
      run_all_checks;
    end
  end

  // ================================================================
  // CHECK TASK: compare a 32-bit value against expected
  // ================================================================
  task check_val;
    input [255:0] name;   // label string (padded)
    input [31:0]  actual;
    input [31:0]  expected;
    begin
      if (actual === expected) begin
        $display("  [PASS]  %-12s = %h", name, actual);
        pass_count = pass_count + 1;
      end else begin
        $display("  [FAIL]  %-12s = %h  (expected %h)", name, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // ================================================================
  // RUN ALL CHECKS
  // ================================================================
  task run_all_checks;
    begin
      pass_count = 0;
      fail_count = 0;

      $display("");
      $display("============================================================");
      $display("  ECE:3350 SISC Autograder - imem.data Test Results");
      $display("============================================================");
      $display("  Simulation time: %0t", $time);
      $display("");

      // ----------------------------------------------------------
      // PART 1 + 2 + 3: Final Register File State
      // ----------------------------------------------------------
      // Expected after ALL instructions in imem.data execute:
      //   R0:  00000000 (always zero)
      //   R1:  00000001
      //   R2:  FF000019
      //   R3:  00000006
      //   R4:  00000006
      //   R5:  FF000019
      //   R6-R15: 00000000

      $display("  --- Register File ---");
      check_val("R0",  uut.u2.ram_array[0],  32'h00000000);
      check_val("R1",  uut.u2.ram_array[1],  32'h00000001);
      check_val("R2",  uut.u2.ram_array[2],  32'hFF000019);
      check_val("R3",  uut.u2.ram_array[3],  32'h00000006);
      check_val("R4",  uut.u2.ram_array[4],  32'h00000006);
      check_val("R5",  uut.u2.ram_array[5],  32'hFF000019);
      check_val("R6",  uut.u2.ram_array[6],  32'h00000000);
      check_val("R7",  uut.u2.ram_array[7],  32'h00000000);
      check_val("R8",  uut.u2.ram_array[8],  32'h00000000);
      check_val("R9",  uut.u2.ram_array[9],  32'h00000000);
      check_val("R10", uut.u2.ram_array[10], 32'h00000000);
      check_val("R11", uut.u2.ram_array[11], 32'h00000000);
      check_val("R12", uut.u2.ram_array[12], 32'h00000000);
      check_val("R13", uut.u2.ram_array[13], 32'h00000000);
      check_val("R14", uut.u2.ram_array[14], 32'h00000000);
      check_val("R15", uut.u2.ram_array[15], 32'h00000000);

      $display("");

      // ----------------------------------------------------------
      // PART 3: Data Memory State
      // ----------------------------------------------------------
      // Expected:
      //   M[8]:  00000006  (from STA R4,#0008)
      //   M[9]:  FF000019  (from STX R5,R1,#0008)

      $display("  --- Data Memory ---");
      check_val("M[8]",  uut.u11.ram_array[8],  32'h00000006);
      check_val("M[9]",  uut.u11.ram_array[9],  32'hFF000019);

      $display("");

      // ----------------------------------------------------------
      // Summary
      // ----------------------------------------------------------
      $display("============================================================");
      $display("  SCORE: %0d / %0d checks passed", pass_count, pass_count + fail_count);
      if (fail_count == 0)
        $display("  STATUS: ALL TESTS PASSED");
      else
        $display("  STATUS: %0d CHECKS FAILED - review output above", fail_count);
      $display("============================================================");
      $display("");

      // ----------------------------------------------------------
      // Diagnostic: Breakdown by project part
      // ----------------------------------------------------------
      $display("  --- Diagnostic Hints ---");
      
      // Part 1 check: R1-R5 intermediate values are overwritten by Parts 2-3,
      // but if branches/loads are completely broken, R1-R5 will reflect Part 1 final vals.
      if (uut.u2.ram_array[4] === 32'h7FFFFFFF && uut.u2.ram_array[2] === 32'hFFFFFFFF) begin
        $display("  WARNING: R2/R4 match end-of-Part1 values, not Part3.");
        $display("           Branches (Part 2) or Loads/Stores (Part 3) may be broken.");
      end
      
      if (uut.u2.ram_array[4] === 32'h00000006 && uut.u2.ram_array[2] === 32'h00000000) begin
        $display("  NOTE: R2=0,R4=6 matches end-of-Part2. Part 2 likely OK.");
        if (uut.u2.ram_array[2] !== 32'hFF000019)
          $display("  WARNING: R2 not updated by LDA in Part 3. Check LOD implementation.");
      end

      if (uut.u11.ram_array[8] === 32'hxxxxxxxx || uut.u11.ram_array[8] === 32'h00000000)
        $display("  WARNING: M[8] was not written. Check STR/STA implementation and dm_we.");

      $display("");
    end
  endtask

endmodule
