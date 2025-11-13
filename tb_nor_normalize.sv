`timescale 1ns/1ps

module tb_nor_normalize;

  // ===== DUT I/O =====
  logic         aos_alu;       // add:0, sub:1 (affects zero detection)
  logic  [7:0]  i_exp;         // constrained: 0..254
  logic [27:0]  i_mant;
  logic         c_alu;         // case select: 1 = case0, 0 = case1

  logic  [7:0]  o_exp;
  logic [27:0]  o_mant;
  logic         o_overflow;
  logic         o_underflow;

  // ===== Instantiate DUT =====
  nor_normalize dut (
    .aos_alu     (aos_alu),
    .i_exp       (i_exp),
    .o_exp       (o_exp),
    .i_mant      (i_mant),
    .o_mant      (o_mant),
    .c_alu       (c_alu),
    .o_overflow  (o_overflow),
    .o_underflow (o_underflow)
  );

  // ===== Utility: leading zero count for 28-bit =====
  function automatic int lzc28 (logic [27:0] x);
    int n;
    begin
      n = 0;
      for (int i = 27; i >= 0; i--) begin
        if (x[i] == 1'b0) n++;
        else break;
      end
      return n; // returns 28 if x == 0
    end
  endfunction

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;

  // Expected signals
  logic  [7:0]  exp_o_exp;
  logic [27:0]  exp_o_mant;
  logic         exp_o_overflow;
  logic         exp_o_underflow;

  // Loop temps (declare before any statements to satisfy strict tools)
  int  n_cnt;
  bit  same;
  int  i; // loop index declared outside for-loop

  // Optional VCD dump
  initial begin
    `ifdef DUMP
      $dumpfile("tb_nor_normalize.vcd");
      $dumpvars(0, tb_nor_normalize);
    `endif
  end

  // Pretty header
  task automatic print_header();
    $display("==============================================================");
    $display("           nor_normalize | Random Test (%0d vectors)          ", VECTORS);
    $display("==============================================================");
  endtask

  // Pretty-print one sample (inputs / expected / DUT / verdict)
  task automatic print_sample(
    int            idx,
    logic          aos_alu_t,
    logic          c_alu_t,
    logic  [7:0]   exp_in_t,
    logic [27:0]   mant_in_t,
    int            n_t,
    logic  [7:0]   exp_e,
    logic [27:0]   mant_e,
    logic          ovf_e,
    logic          unf_e,
    logic  [7:0]   exp_d,
    logic [27:0]   mant_d,
    logic          ovf_d,
    logic          unf_d,
    bit            is_pass
  );
    $display("[IN ] #%0d  aos_alu=%0d  c_alu=%0d  i_exp=0x%02h  i_mant=0x%07h  (n=%0d)",
              idx, aos_alu_t, c_alu_t, exp_in_t, mant_in_t, n_t);
    $display("[EXP]        o_exp=0x%02h  o_mant=0x%07h  o_overflow=%0d  o_underflow=%0d",
              exp_e, mant_e, ovf_e, unf_e);
    $display("[DUT]        o_exp=0x%02h  o_mant=0x%07h  o_overflow=%0d  o_underflow=%0d   ==> %s",
              exp_d, mant_d, ovf_d, unf_d, (is_pass ? "PASS" : "FAIL"));
    $display("--------------------------------------------------------------");
  endtask

  // Compute expected behavior per the given specification
  task automatic compute_expected(
    input  logic        aos_alu_i,
    input  logic        c_alu_i,
    input  logic  [7:0] i_exp_i,
    input  logic [27:0] i_mant_i,
    output logic  [7:0] e_exp,
    output logic [27:0] m_exp,
    output logic        ov_exp,
    output logic        un_exp,
    output int          n_out
  );
    // ---- declare everything first (no statements before declarations) ----
    logic w0, w1, z, zero;

    // case0 temps
    logic  [7:0]  e0;
    logic [27:0]  m0;
    logic         ov0;

    // case1 temps
    int           n;
    logic  [7:0]  e1;
    logic [27:0]  m1;
    logic         un1;

    // ---- zero detection ----
    w0   = ~((|i_exp_i) | (|i_mant_i));  // 1 when i_exp==0 AND i_mant==0
    w1   = ~(|i_mant_i);                 // 1 when i_mant==0
    z    = aos_alu_i ? w0 : w1;
    zero = (~c_alu_i) & z;               // only active when c_alu==0

    // ---- case0 (c_alu=1): right shift mant, exp+1, overflow if 255 ----
    e0  = i_exp_i + 8'd1;                // i_exp in [0..254] -> e0 in [1..255]
    m0  = i_mant_i >> 1;
    ov0 = (e0 == 8'd255);                // overflow only when i_exp==254

    // ---- case1 (c_alu=0): normalize left by LZC, subtract n with floor at 0 ----
    n  = lzc28(i_mant_i);
    e1 = (i_exp_i > n[7:0]) ? (i_exp_i - n[7:0]) : 8'd0;
    m1 = i_mant_i << n;
    un1 = (e1 == 8'd0);

    // ---- final selection with zero override ----
    if (zero) begin
      e_exp  = 8'd0;
      m_exp  = 28'd0;
      ov_exp = 1'b0;
      un_exp = 1'b1;
    end else if (c_alu_i) begin
      e_exp  = e0;
      m_exp  = m0;
      ov_exp = ov0;
      un_exp = 1'b0;
    end else begin
      e_exp  = e1;
      m_exp  = m1;
      ov_exp = 1'b0;     // no overflow in case1
      un_exp = un1;
    end

    n_out = n;
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Reproducible seed
    void'($urandom(32'hC0FFEE11));

    for (i = 0; i < VECTORS; i++) begin
      // Randomize inputs under constraints
      aos_alu = $urandom_range(0, 1);
      c_alu   = $urandom_range(0, 1);
      i_exp   = $urandom_range(0, 254);      // 0..254
      i_mant  = $urandom() & 28'hFFFFFFF;    // 28 bits (7 hex digits)

      // Combinational settle
      #1;

      // Compute expected
      compute_expected(aos_alu, c_alu, i_exp, i_mant,
                       exp_o_exp, exp_o_mant, exp_o_overflow, exp_o_underflow, n_cnt);

      // Compare
      same = (o_exp        === exp_o_exp)      &&
             (o_mant       === exp_o_mant)     &&
             (o_overflow   === exp_o_overflow) &&
             (o_underflow  === exp_o_underflow);

      if (same) pass_cnt++; else fail_cnt++;

      // Print per-vector block
      print_sample(i, aos_alu, c_alu, i_exp, i_mant, n_cnt,
                   exp_o_exp, exp_o_mant, exp_o_overflow, exp_o_underflow,
                   o_exp,     o_mant,     o_overflow,     o_underflow,
                   same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
