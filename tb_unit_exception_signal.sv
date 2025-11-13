`timescale 1ns/1ps

module tb_unit_exception_signal;

  // ===== DUT I/O =====
  logic        i_aos;                    // 1=ADD, 0=SUB (used for NaN rule)
  logic        i_signA, i_signB;
  logic [7:0]  i_expA,  i_expB;
  logic [22:0] i_mantA, i_mantB;

  logic        e_mt, spe_m, spe_sig;

  // ===== Instantiate DUT =====
  unit_exception_signal dut (
    .i_aos   (i_aos),
    .i_signA (i_signA),
    .i_signB (i_signB),
    .i_expA  (i_expA),
    .i_expB  (i_expB),
    .i_mantA (i_mantA),
    .i_mantB (i_mantB),
    .e_mt    (e_mt),
    .spe_m   (spe_m),
    .spe_sig (spe_sig)
  );

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int idx;       // loop index
  bit same;      // compare result

  // Expected outputs
  logic exp_e_mt, exp_spe_m, exp_spe_sig;

  // Debug classification (for readable prints)
  logic ai_dbg, bi_dbg, az_dbg, bz_dbg; // A/B are +/−Inf or Zero

  // Optional VCD dump
  initial begin
    `ifdef DUMP
      $dumpfile("tb_unit_exception_signal.vcd");
      $dumpvars(0, tb_unit_exception_signal);
    `endif
  end

  // ===== Pretty header =====
  task automatic print_header();
    $display("==========================================================================");
    $display("                    unit_exception_signal | Self-Checking                  ");
    $display("                100 randomized inputs (Inf/Zero/Normal mix)               ");
    $display("  Expect rules:                                                            ");
    $display("    e_mt     = 1 iff (expA==255) & (expB==0)                               ");
    $display("    spe_sig  = (A is Inf & B is Inf) | (A is Inf & B is 0) | (A is 0 & B is Inf)");
    $display("    spe_m    = NaN cases per table:                                        ");
    $display("               ADD(1):  (+Inf) + (-Inf) or (-Inf) + (+Inf)                 ");
    $display("               SUB(0):  (+Inf) - (+Inf) or (-Inf) - (-Inf)                 ");
    $display("==========================================================================");
  endtask

  // ===== Pretty print one vector =====
  task automatic print_case(
    int          id,
    logic        aos_t,
    logic        sA_t, logic sB_t,
    logic [7:0]  eA_t, logic [7:0] eB_t,
    logic [22:0] mA_t, logic [22:0] mB_t,
    logic        ai_t, logic bi_t, logic az_t, logic bz_t,
    logic        exp_em, logic exp_sm, logic exp_ss,
    logic        dut_em, logic dut_sm, logic dut_ss,
    bit          is_pass
  );
    $display("[IN ] #%0d  aos=%0d  signA=%0d signB=%0d  expA=0x%02h expB=0x%02h  mantA=0x%06h mantB=0x%06h",
             id, aos_t, sA_t, sB_t, eA_t, eB_t, mA_t, mB_t);
    $display("      classify: A{inf=%0d zero=%0d}  B{inf=%0d zero=%0d}", ai_t, az_t, bi_t, bz_t);
    $display("[EXP] e_mt=%0d  spe_m(NaN)=%0d  spe_sig=%0d",
             exp_em, exp_sm, exp_ss);
    $display("[DUT] e_mt=%0d  spe_m(NaN)=%0d  spe_sig=%0d   ==> %s",
             dut_em, dut_sm, dut_ss, (is_pass ? "PASS" : "FAIL"));
    $display("--------------------------------------------------------------------------");
  endtask

  // ===== Expected model (mirrors the spec you provided) =====
  task automatic compute_expected(
    input  logic        aos_i,             // 1=ADD, 0=SUB
    input  logic        sA_i, sB_i,
    input  logic [7:0]  eA_i, eB_i,
    input  logic [22:0] mA_i, mB_i,
    output logic        e_mt_o, spe_m_o, spe_sig_o,
    output logic        ai_o, bi_o, az_o, bz_o
  );
    // Declarations first (tool-friendly)
    logic ai, bi, az, bz;
    logic signs_xor, signs_xnor;
    logic all_inf, inf_zero, zero_inf;
    logic is_add, is_sub;

    // Inf / Zero classification
    ai = (&eA_i) & (~|mA_i); // A is Inf  (exp=255, mant=0)
    bi = (&eB_i) & (~|mB_i); // B is Inf
    az = (~|eA_i) & (~|mA_i); // A is Zero (exp=0, mant=0)
    bz = (~|eB_i) & (~|mB_i); // B is Zero

    ai_o = ai; bi_o = bi; az_o = az; bz_o = bz;

    // e_mt rule from your description
    e_mt_o = ((eA_i == 8'hFF) && (eB_i == 8'h00));

    // spe_sig rule
    all_inf  = ai & bi;
    inf_zero = ai & bz;
    zero_inf = az & bi;
    spe_sig_o = all_inf | inf_zero | zero_inf;

    // NaN rule by table
    signs_xor  = sA_i ^  sB_i;
    signs_xnor = ~(sA_i ^ sB_i);

    is_add = (aos_i == 1'b1);
    is_sub = (aos_i == 1'b0);

    // Only when both are Inf
    if (all_inf) begin
      if (is_add)      spe_m_o = signs_xor;   // +Inf + -Inf -> NaN
      else /* SUB */   spe_m_o = signs_xnor;  // +Inf - +Inf, -Inf - -Inf -> NaN
    end else begin
      spe_m_o = 1'b0;
    end
  endtask

  // ===== Random pattern generator (bias to cover Inf/Zero/Normal) =====
  task automatic rand_fp_fields(
    output logic        s_o,
    output logic [7:0]  e_o,
    output logic [22:0] m_o
  );
    // Declarations first
    int sel;

    sel = $urandom_range(0, 9);
    s_o = $urandom_range(0, 1);

    // ~30% normal, ~20% zeros, ~30% inf, ~20% NaN-like (ignored by module)
    // Adjusted to get frequent special cases.
    case (sel)
      0,1,2: begin // ZERO
        e_o = 8'h00;
        m_o = 23'd0;
      end
      3,4,5: begin // INF
        e_o = 8'hFF;
        m_o = 23'd0;
      end
      6,7: begin // NaN (not used by module for spe_sig, but good noise)
        e_o = 8'hFF;
        m_o = $urandom_range(1, 23'h7FFFFF);
      end
      default: begin // NORMAL
        e_o = $urandom_range(1, 254);
        m_o = $urandom();
      end
    endcase
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Deterministic seed
    void'($urandom(32'hC0DE_CAFE));

    for (idx = 0; idx < VECTORS; idx++) begin
      // Random op and operands (biased)
      i_aos   = $urandom_range(0, 1); // 1=ADD, 0=SUB
      rand_fp_fields(i_signA, i_expA, i_mantA);
      rand_fp_fields(i_signB, i_expB, i_mantB);

      // Encourage some e_mt==1 patterns (A exp=255, B exp=0)
      if ((idx % 10) == 3) begin
        i_expA  = 8'hFF; i_mantA = 23'd0; // A = Inf
        i_expB  = 8'h00; i_mantB = 23'd0; // B = 0
      end

      // Combinational settle
      #1;

      // Compute expected
      compute_expected(i_aos, i_signA, i_signB, i_expA, i_expB, i_mantA, i_mantB,
                       exp_e_mt, exp_spe_m, exp_spe_sig,
                       ai_dbg, bi_dbg, az_dbg, bz_dbg);

      // Compare
      same = (e_mt    === exp_e_mt)    &&
             (spe_m   === exp_spe_m)   &&
             (spe_sig === exp_spe_sig);

      if (same) pass_cnt++; else fail_cnt++;

      // Print vector
      print_case(idx, i_aos, i_signA, i_signB, i_expA, i_expB, i_mantA, i_mantB,
                 ai_dbg, bi_dbg, az_dbg, bz_dbg,
                 exp_e_mt, exp_spe_m, exp_spe_sig,
                 e_mt,     spe_m,     spe_sig,
                 same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
