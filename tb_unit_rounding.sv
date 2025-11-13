`timescale 1ns/1ps

module tb_unit_rounding;

  // ===== DUT I/O =====
  logic  [7:0]  i_exp;
  logic [27:0]  i_mant;
  logic         i_ov_fl, i_un_fl;

  logic  [7:0]  o_exp;
  logic [22:0]  o_mant;
  logic         o_ov_fl, o_un_fl;

  // ===== Instantiate DUT =====
  unit_rounding dut (
    .i_exp   (i_exp),
    .i_mant  (i_mant),
    .i_ov_fl (i_ov_fl),
    .i_un_fl (i_un_fl),
    .o_exp   (o_exp),
    .o_mant  (o_mant),
    .o_ov_fl (o_ov_fl),
    .o_un_fl (o_un_fl)
  );

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int idx;
  bit same;  // declared at module scope (not inside initial)

  // Expected signals
  logic  [7:0]  exp_o_exp;
  logic [22:0]  exp_o_mant;
  logic         exp_o_ov_fl, exp_o_un_fl;

  // Debug helpers (for clear prints)
  logic        en_dbg, r_up_dbg, sel_dbg;
  logic        L_dbg, G_dbg, R_dbg, S_dbg;
  logic [22:0] m0_dbg, m1_dbg;
  logic  [7:0] e0_dbg, e1_dbg;
  logic        carry_dbg;

  // Optional VCD
  initial begin
    `ifdef DUMP
      $dumpfile("tb_unit_rounding.vcd");
      $dumpvars(0, tb_unit_rounding);
    `endif
  end

  // ===== Pretty header =====
  task automatic print_header();
    $display("======================================================================");
    $display("                     unit_rounding — Self-Check (100)                  ");
    $display("     Mirrors RTL: sel=(~i_ov_fl)&r_up; r_up = L?G : (G & (R|S))        ");
    $display("        L=i_mant[4], G=i_mant[3], R=i_mant[2], S=|i_mant[1:0]          ");
    $display("======================================================================");
  endtask

  // ===== Pretty print one vector =====
  task automatic print_case(
    int           id,
    logic  [7:0]  exp_i,
    logic [27:0]  mant_i,
    logic         ov_i,
    logic         un_i,
    logic         en_t, logic r_up_t, logic sel_t,
    logic         L_t, logic G_t, logic R_t, logic S_t,
    logic  [7:0]  e0_t,  logic [22:0] m0_t,
    logic  [7:0]  e1_t,  logic [22:0] m1_t, logic carry_t,
    logic  [7:0]  exp_e, logic [22:0] mant_e, logic ov_e, logic un_e,
    logic  [7:0]  exp_d, logic [22:0] mant_d, logic ov_d, logic un_d,
    bit           is_pass
  );
    $display("[IN ] #%0d  i_exp=0x%02h  i_mant=0x%07h  i_ov=%0d  i_un=%0d",
             id, exp_i, mant_i, ov_i, un_i);
    $display("      en=%0d  r_up=%0d  sel=%0d   (L=%0d G=%0d R=%0d S=%0d)",
             en_t, r_up_t, sel_t, L_t, G_t, R_t, S_t);
    $display("      case0: e0=0x%02h m0=0x%06h   case1: e1=0x%02h m1=0x%06h carry=%0d",
             e0_t, m0_t, e1_t, m1_t, carry_t);
    $display("[EXP] o_exp=0x%02h  o_mant=0x%06h  o_ov=%0d  o_un=%0d",
             exp_e, mant_e, ov_e, un_e);
    $display("[DUT] o_exp=0x%02h  o_mant=0x%06h  o_ov=%0d  o_un=%0d   ==> %s",
             exp_d, mant_d, ov_d, un_d, (is_pass ? "PASS" : "FAIL"));
    $display("----------------------------------------------------------------------");
  endtask

  // ===== Reference model that mirrors your RTL exactly =====
  // sel = (~i_ov_fl) & r_up
  // r_up = i_mant[4] ? i_mant[3] : (i_mant[3] & |i_mant[2:0])
  // case0 (sel=0): e0=i_exp; m0=i_mant[26:4]; flags pass-through
  // case1 (sel=1): add 1 ULP to m0; if carry then e1=e0+1, m1=0, ov1=(e1==255)
  //                underflow passes through
  task automatic compute_expected(
    input  logic  [7:0]  i_exp_i,
    input  logic [27:0]  i_mant_i,
    input  logic         i_ov_i,
    input  logic         i_un_i,
    output logic  [7:0]  o_exp_e,
    output logic [22:0]  o_mant_e,
    output logic         o_ov_e,
    output logic         o_un_e,
    // debug outs
    output logic         en_o, r_up_o, sel_o,
    output logic         L_o, G_o, R_o, S_o,
    output logic  [7:0]  e0_o, e1_o,
    output logic [22:0]  m0_o, m1_o,
    output logic         carry_o
  );
    // ---- locals declared first ----
    logic        en, r_up, sel;
    logic        L, G, R, S;
    logic  [7:0] e0, e1;
    logic [22:0] m0, m1;
    logic [22:0] mant_base, mant_sum;
    logic        carry;
    logic        ov1, un1;

    // enable if not overflow
    en = ~i_ov_i;

    // L/G/R/S extraction
    L = i_mant_i[4];
    G = i_mant_i[3];
    R = i_mant_i[2];
    S = |i_mant_i[1:0];

    // RTL r_up
    r_up = L ? G : (G & (R | S));

    sel = en & r_up;

    // case0
    e0 = i_exp_i;
    m0 = i_mant_i[26:4];

    // case1
    mant_base = m0;
    {carry, mant_sum} = {1'b0, mant_base} + 24'd1; // 23b + 1ULP -> 24b result

    if (carry) begin
      e1  = i_exp_i + 8'd1;
      m1  = 23'd0;                 // normalize on carry (fraction rolls over)
      ov1 = (e1 == 8'd255);
    end
    else begin
      e1  = i_exp_i;
      m1  = mant_sum;
      ov1 = 1'b0;
    end

    un1 = i_un_i; // pass-through

    // final select
    if (sel) begin
      o_exp_e  = e1;
      o_mant_e = m1;
      o_ov_e   = ov1;
      o_un_e   = un1;
    end
    else begin
      o_exp_e  = e0;
      o_mant_e = m0;
      o_ov_e   = i_ov_i;
      o_un_e   = i_un_i;
    end

    // debug outs
    en_o   = en;
    r_up_o = r_up;
    sel_o  = sel;
    L_o    = L;  G_o = G;  R_o = R;  S_o = S;
    e0_o   = e0; e1_o = e1;
    m0_o   = m0; m1_o = m1;
    carry_o = carry;
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // deterministic seed
    void'($urandom(32'hC0FFEE11));

    for (idx = 0; idx < VECTORS; idx++) begin
      // Randomize inputs
      i_exp   = $urandom();                    // 8-bit
      i_mant  = $urandom() & 28'hFFFFFFF;      // 28-bit (7 hex digits)
      i_ov_fl = $urandom_range(0, 1);
      i_un_fl = $urandom_range(0, 1);

      // settle
      #1;

      // Compute expected
      compute_expected(
        i_exp, i_mant, i_ov_fl, i_un_fl,
        exp_o_exp, exp_o_mant, exp_o_ov_fl, exp_o_un_fl,
        en_dbg, r_up_dbg, sel_dbg,
        L_dbg, G_dbg, R_dbg, S_dbg,
        e0_dbg, e1_dbg, m0_dbg, m1_dbg, carry_dbg
      );

      // Compare
      same = (o_exp   === exp_o_exp)   &&
             (o_mant  === exp_o_mant)  &&
             (o_ov_fl === exp_o_ov_fl) &&
             (o_un_fl === exp_o_un_fl);

      if (same) pass_cnt++; else fail_cnt++;

      // Print detailed block
      print_case(idx,
        i_exp, i_mant, i_ov_fl, i_un_fl,
        en_dbg, r_up_dbg, sel_dbg,
        L_dbg, G_dbg, R_dbg, S_dbg,
        e0_dbg, m0_dbg, e1_dbg, m1_dbg, carry_dbg,
        exp_o_exp, exp_o_mant, exp_o_ov_fl, exp_o_un_fl,
        o_exp,     o_mant,     o_ov_fl,     o_un_fl,
        same
      );
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
