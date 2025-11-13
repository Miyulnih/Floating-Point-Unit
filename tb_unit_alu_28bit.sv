`timescale 1ns/1ps

module tb_unit_alu_28bit;
  // DUT I/O
  logic [27:0] augend, addend;
  logic        aos;      // 0=ADD, 1=SUB (A - B)
  wire  [27:0] result;
  wire         c_alu;

  // Instantiate DUT
  unit_alu_28bit dut (
    .augend (augend),
    .addend (addend),
    .aos    (aos),
    .result (result),
    .c_alu  (c_alu)
  );

  // Expecteds
  logic [28:0] sum_ext;       // 29-bit to hold carry/borrow
  logic [27:0] exp_result;
  logic        exp_c_alu;

  // Counters
  int pass_cnt = 0;
  int fail_cnt = 0;

  // In ra 1 vector
  task automatic run_one(input int idx);
    string op;
    bit pass;
    begin
      // Randomize (mask 28-bit)
      augend = $urandom() & 28'h0FFFFFFF;
      addend = $urandom() & 28'h0FFFFFFF;
      aos    = $urandom_range(0,1);

      // Mo hinh vang (phu hop add/sub 2's complement):
      // ADD: {0,A} + {0,B} + 0
      // SUB: {0,A} + {0,~B} + 1  (c_alu = 1 => no-borrow)
      #1;
      sum_ext    = {1'b0, augend} + (aos ? {1'b0, ~addend} : {1'b0, addend}) + (aos ? 1 : 0);
      exp_result = sum_ext[27:0];
      exp_c_alu  = sum_ext[28];

      pass = (result === exp_result) && (c_alu === exp_c_alu);
      if (pass) pass_cnt++; else fail_cnt++;

      op = aos ? "SUB" : "ADD";

      // output
      $display("%0t | %2d | OP=%s | A=%07h  B=%07h | DUT: c_alu=%0d result=%07h | EXP: c_alu=%0d result=%07h | %s",
               $time, idx, op, augend, addend, c_alu, result, exp_c_alu, exp_result,
               pass ? "PASS" : "FAIL");
    end
  endtask

  initial begin
    // Header
    $display("time | Id | OP  |            Inputs            |            DUT Outputs           |           Expected Outputs       | Result");
    $display("-----+----+-----+-------------------------------+----------------------------------+----------------------------------+--------");


    // void'($urandom(32'h28_ALU_SEED));

    // 50 random samples
    for (int i = 0; i < 50; i++) begin
      run_one(i);
    end

    // Summary
    $display("----------------------------------------------------------------------------------------------");
    $display("SUMMARY: PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
    $display("----------------------------------------------------------------------------------------------");

    if (fail_cnt != 0) $error("unit_alu_28bit: %0d / 50 samples FAILED.", fail_cnt);
    else               $display("unit_alu_28bit: All 50 samples PASSED.");

    $finish;
  end
endmodule
