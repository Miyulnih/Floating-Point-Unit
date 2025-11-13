`timescale 1ns/1ps

module tb_unit_sel_aug_add;

  // ===== DUT I/O =====
  logic [22:0] Mant_A, Mant_B;
  logic  [7:0] E_sub;
  logic        Ce;

  logic [27:0] Augend, Addend;
  logic        C_mant;

  // ===== Instantiate DUT =====
  unit_sel_aug_add dut (
    .Mant_A (Mant_A),
    .Mant_B (Mant_B),
    .E_sub  (E_sub),
    .Ce     (Ce),
    .Augend (Augend),
    .Addend (Addend),
    .C_mant (C_mant)
  );

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int idx;          // loop index
  bit same;         // overall comparison

  // Expected signals
  logic [27:0] exp_Augend, exp_Addend;
  logic        exp_C_mant;

  // Debug (for readable prints)
  logic [27:0] dbg_M_A, dbg_M_B;
  logic [27:0] dbg_M_em, dbg_M_el, dbg_M_sr;
  int          dbg_shift;

  // ===== Optional VCD =====
  initial begin
    `ifdef DUMP
      $dumpfile("tb_unit_sel_aug_add.vcd");
      $dumpvars(0, tb_unit_sel_aug_add);
    `endif
  end

  // ===== Pretty header =====
  task automatic print_header();
    $display("==================================================================");
    $display("  unit_sel_aug_add — Self-checking TB (100 random vectors)        ");
    $display("  Extend: {1'b1, mant[22:0], 4'b0000}; right-shift by E_sub<=28   ");
    $display("  Compare M_em vs M_sr; C_mant=1 when M_em > M_sr;                 ");
    $display("  Augend = larger, Addend = smaller.                              ");
    $display("==================================================================");
  endtask

  // ===== Pretty print one vector =====
  task automatic print_case(
    int            id,
    logic          ce_t,
    logic  [7:0]   e_sub_t,
    logic [22:0]   a_t,
    logic [22:0]   b_t,
    logic [27:0]   M_A_t,
    logic [27:0]   M_B_t,
    logic [27:0]   M_em_t,
    logic [27:0]   M_el_t,
    int            sh_t,
    logic [27:0]   M_sr_t,
    logic [27:0]   exp_aug_t,
    logic [27:0]   exp_add_t,
    logic          exp_c_t,
    logic [27:0]   dut_aug_t,
    logic [27:0]   dut_add_t,
    logic          dut_c_t,
    bit            is_pass
  );
    $display("[IN ] #%0d  Ce=%0d  E_sub=%0d  Mant_A=0x%06h  Mant_B=0x%06h",
              id, ce_t, e_sub_t, a_t, b_t);
    $display("      extend: M_A=0x%07h  M_B=0x%07h", M_A_t, M_B_t);
    $display("      select: M_em=0x%07h  M_el=0x%07h  >> %0d -> M_sr=0x%07h",
              M_em_t, M_el_t, sh_t, M_sr_t);
    $display("[EXP] Augend=0x%07h  Addend=0x%07h  C_mant=%0d",
              exp_aug_t, exp_add_t, exp_c_t);
    $display("[DUT] Augend=0x%07h  Addend=0x%07h  C_mant=%0d  ==> %s",
              dut_aug_t, dut_add_t, dut_c_t, (is_pass ? "PASS" : "FAIL"));
    $display("------------------------------------------------------------------");
  endtask

  // ===== Reference model (matches your spec exactly) =====
  task automatic compute_expected(
    input  logic [22:0] Mant_A_i,
    input  logic [22:0] Mant_B_i,
    input  logic  [7:0] E_sub_i,
    input  logic        Ce_i,
    output logic [27:0] Augend_o,
    output logic [27:0] Addend_o,
    output logic        C_mant_o,
    // debug outs
    output logic [27:0] M_A_o,
    output logic [27:0] M_B_o,
    output logic [27:0] M_em_o,
    output logic [27:0] M_el_o,
    output int          shift_o,
    output logic [27:0] M_sr_o
  );
    // Declarations first
    logic [27:0] M_A, M_B;
    logic [27:0] M_em, M_el;
    logic [27:0] M_sr;
    int          sh;
    logic        sel;

    // 1) Extend: {1'b1, mant[22:0], 4'b0000}
    M_A = {1'b1, Mant_A_i, 4'b0000};
    M_B = {1'b1, Mant_B_i, 4'b0000};

    // 2) Select em/el by Ce (Ce=1 => shift A; Ce=0 => shift B)
    M_em = Ce_i ? M_B : M_A; // not shifted
    M_el = Ce_i ? M_A : M_B; // to be shifted

    // 3) Logical right shift by E_sub (clamp 0..28)
    sh   = (E_sub_i > 8'd28) ? 28 : E_sub_i;
    M_sr = (sh == 0) ? M_el : (M_el >> sh);

    // 4) Compare
    sel = (M_em > M_sr);

    // 5) Choose Augend/Addend
    Augend_o = sel ? M_em : M_sr;
    Addend_o = sel ? M_sr : M_em;

    // 6) C_mant
    C_mant_o = sel;

    // debug outs
    M_A_o   = M_A;
    M_B_o   = M_B;
    M_em_o  = M_em;
    M_el_o  = M_el;
    M_sr_o  = M_sr;
    shift_o = sh;
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Reproducible seed
    void'($urandom(32'hA55E_ED01));

    for (idx = 0; idx < VECTORS; idx++) begin
      // Randomize inputs (E_sub within 0..28 as required)
      Ce     = $urandom_range(0, 1);
      E_sub  = $urandom_range(0, 28);
      Mant_A = $urandom() & 23'h7FFFFF;
      Mant_B = $urandom() & 23'h7FFFFF;

      // Combinational settle
      #1;

      // Compute expected
      compute_expected(
        Mant_A, Mant_B, E_sub, Ce,
        exp_Augend, exp_Addend, exp_C_mant,
        dbg_M_A, dbg_M_B, dbg_M_em, dbg_M_el, dbg_shift, dbg_M_sr
      );

      // Compare
      same = (Augend === exp_Augend) &&
             (Addend === exp_Addend) &&
             (C_mant === exp_C_mant);

      if (same) pass_cnt++; else fail_cnt++;

      // Print
      print_case(idx, Ce, E_sub, Mant_A, Mant_B,
                 dbg_M_A, dbg_M_B, dbg_M_em, dbg_M_el, dbg_shift, dbg_M_sr,
                 exp_Augend, exp_Addend, exp_C_mant,
                 Augend,     Addend,     C_mant,
                 same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
