`timescale 1ns/1ps

module tb_CLA24bit_sep;
  // DUT I/O
  logic [23:0] A, B;
  logic        Ci;
  wire  [23:0] S;
  wire         Co;

  // Instantiate DUT
  CLA24bit dut (
    .A (A),
    .B (B),
    .Ci(Ci),
    .S (S),
    .Co(Co)
  );

  // Counters
  int pass_cnt = 0;
  int fail_cnt = 0;

  // Expecteds
  logic [24:0] exp_sum;
  logic [23:0] exp_S;
  logic        exp_Co;

  task automatic run_one(input int idx);
    bit pass;
    begin
      A  = $urandom() & 24'hFFFFFF;
      B  = $urandom() & 24'hFFFFFF;
      Ci = $urandom_range(0,1);
      #1;

      // Golden model
      exp_sum = A + B + Ci;
      exp_S   = exp_sum[23:0];
      exp_Co  = exp_sum[24];

      pass = (S === exp_S) && (Co === exp_Co);

      if (pass) pass_cnt++; else fail_cnt++;

      $display("%5d | A=%06h B=%06h Ci=%0d | DUT: Co=%0d S=%06h | EXP: Co=%0d S=%06h | %s",
               idx, A, B, Ci, Co, S, exp_Co, exp_S, pass ? "PASS" : "FAIL");
    end
  endtask

  initial begin
    // Header
    $display("--------------------------------------------------------------------------");
    for (int i = 0; i < 50; i++) begin
      run_one(i);
    end

    $display("--------------------------------------------------------------------------");
    $display("SUMMARY: PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
    $display("--------------------------------------------------------------------------");

    if (fail_cnt != 0) $error("CLA24bit: %0d / 50 samples FAILED.", fail_cnt);
    else               $display("CLA24bit: All 50 samples PASSED.");

    $finish;
  end
endmodule
