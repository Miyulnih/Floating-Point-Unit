`timescale 1ns/1ps

module tb_unit_sel_exp;

  // ===== DUT I/O =====
  logic [7:0] ExpA, ExpB;
  logic [7:0] o_Exp, E_sub;
  logic       Ce_lt;

  // ===== Instantiate DUT =====
  unit_sel_exp dut (
    .ExpA  (ExpA),
    .ExpB  (ExpB),
    .o_Exp (o_Exp),
    .E_sub (E_sub),
    .Ce_lt (Ce_lt)
  );

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int i;            // loop index declared up-front
  bit same;         // comparison result declared up-front

  // Expected values
  logic [7:0] exp_o_Exp;
  logic [7:0] exp_E_sub;
  logic       exp_Ce_lt;

  // Optional VCD dump
  initial begin
    `ifdef DUMP
      $dumpfile("tb_unit_sel_exp.vcd");
      $dumpvars(0, tb_unit_sel_exp);
    `endif
  end

  // ===== Pretty header =====
  task automatic print_header();
    $display("==============================================================");
    $display("               unit_sel_exp | Random Self-Check               ");
    $display("                 100 random input vectors                     ");
    $display("==============================================================");
  endtask

  // ===== Pretty-print one vector =====
  task automatic print_case(
    int          idx,
    logic [7:0]  A,
    logic [7:0]  B,
    logic [7:0]  exp_oexp,
    logic [7:0]  exp_esub,
    logic        exp_celt,
    logic [7:0]  dut_oexp,
    logic [7:0]  dut_esub,
    logic        dut_celt,
    bit          is_pass
  );
    $display("[IN ] #%0d  ExpA=0x%02h  ExpB=0x%02h", idx, A, B);
    $display("[EXP] o_Exp=0x%02h  E_sub=0x%02h  Ce_lt=%0d", exp_oexp, exp_esub, exp_celt);
    $display("[DUT] o_Exp=0x%02h  E_sub=0x%02h  Ce_lt=%0d   ==> %s",
             dut_oexp, dut_esub, dut_celt, (is_pass ? "PASS" : "FAIL"));
    $display("--------------------------------------------------------------");
  endtask

  // ===== Reference model (matches the described behavior) =====
  // - Ce_lt = (ExpA < ExpB) ? 1 : 0
  // - o_Exp = max(ExpA, ExpB)
  // - E_sub = |ExpA - ExpB|  (i.e., max - min)
  task automatic compute_expected(
    input  logic [7:0] A_i,
    input  logic [7:0] B_i,
    output logic [7:0] Oexp_o,
    output logic [7:0] Esub_o,
    output logic       Celt_o
  );
    // Declarations first (tool-friendly)
    logic [7:0] max_e, min_e;

    Celt_o = (A_i < B_i);
    max_e  = (A_i < B_i) ? B_i : A_i;
    min_e  = (A_i < B_i) ? A_i : B_i;

    Oexp_o = max_e;             // the larger exponent
    Esub_o = max_e - min_e;     // non-negative difference (0..255)
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Deterministic seed
    void'($urandom(32'hABCD_1234));

    for (i = 0; i < VECTORS; i++) begin
      // Randomize inputs (full 8-bit range)
      ExpA = $urandom_range(0, 255);
      ExpB = $urandom_range(0, 255);

      // Allow combinational settle
      #1;

      // Compute expected
      compute_expected(ExpA, ExpB, exp_o_Exp, exp_E_sub, exp_Ce_lt);

      // Compare DUT vs expected
      same = (o_Exp === exp_o_Exp) &&
             (E_sub === exp_E_sub) &&
             (Ce_lt === exp_Ce_lt);

      if (same) pass_cnt++; else fail_cnt++;

      // Print this vector
      print_case(i, ExpA, ExpB,
                 exp_o_Exp, exp_E_sub, exp_Ce_lt,
                 o_Exp,     E_sub,     Ce_lt,
                 same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
