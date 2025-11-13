`timescale 1ns/1ps

module tb_FPU;

  // ===== DUT I/O =====
  logic [31:0] i_32_a, i_32_b;
  logic        i_add_sub;   // 0 = add, 1 = sub

  logic [31:0] o_32_s;
  logic        o_ov_flag, o_un_flag;

  // ===== Instantiate DUT =====
  FPU dut (
    .i_32_a    (i_32_a),
    .i_32_b    (i_32_b),
    .i_add_sub (i_add_sub),
    .o_32_s    (o_32_s),
    .o_ov_flag (o_ov_flag),
    .o_un_flag (o_un_flag)
  );

  // ===== Helpers: field extractors =====
  function automatic logic        get_sig (logic [31:0] x); get_sig = x[31];    endfunction
  function automatic logic [7:0]  get_exp (logic [31:0] x); get_exp = x[30:23]; endfunction
  function automatic logic [22:0] get_man (logic [31:0] x); get_man = x[22:0];  endfunction

  // ===== Reference model using IEEE-754 shortreal =====
  // Uses $bitstoshortreal and $shortrealtobits (portable; no packed unions).
  task automatic ref_fpu
  (
    input  logic [31:0] A_bits,
    input  logic [31:0] B_bits,
    input  logic        add_sub,     // 0 = add, 1 = sub
    output logic [31:0] S_bits_ref,
    output logic        ov_ref,
    output logic        un_ref
  );
    // Declarations first
    shortreal a_s, b_s, r_s;
    logic [31:0] s_bits;
    logic [7:0]  e_ref;

    a_s    = $bitstoshortreal(A_bits);
    b_s    = $bitstoshortreal(B_bits);
    r_s    = add_sub ? (a_s - b_s) : (a_s + b_s);
    s_bits = $shortrealtobits(r_s);

    S_bits_ref = s_bits;

    // Flags by your spec after normalization/rounding:
    // ov = (exp==255), un = (exp==0).
    e_ref = s_bits[30:23];
    ov_ref = (e_ref == 8'hFF);
    un_ref = (e_ref == 8'h00);
  endtask

  // ===== Pretty printing =====
  task automatic print_header();
    $display("================================================================================");
    $display("                                        FPU TB                                  ");
    $display("                    100 random add/sub — PASS / WARNING / FAIL                  ");
    $display(" Policy: PASS=all match; WARNING=sign&exp match but mant/flags differ;          ");
    $display("         FAIL=2+ outputs differ OR single mismatch on sign or exponent.         ");
    $display("================================================================================");
  endtask

  task automatic print_case
  (
    int            idx,
    logic [31:0]   A,
    logic [31:0]   B,
    logic          op,            // 0=add,1=sub
    logic [31:0]   S_exp,
    logic          ov_exp,
    logic          un_exp,
    logic [31:0]   S_dut,
    logic          ov_dut,
    logic          un_dut,
    string         verdict,
    int            diff_count,
    logic          ds, de, dm, dov, dun
  );
    $display("[IN ] #%0d  op=%0d  A=0x%08h  B=0x%08h", idx, op, A, B);
    $display("      A: s=%0d e=0x%02h m=0x%06h   B: s=%0d e=0x%02h m=0x%06h",
             get_sig(A), get_exp(A), get_man(A),
             get_sig(B), get_exp(B), get_man(B));
    $display("[EXP] S=0x%08h  (s=%0d e=0x%02h m=0x%06h)  ov=%0d un=%0d",
             S_exp, get_sig(S_exp), get_exp(S_exp), get_man(S_exp), ov_exp, un_exp);
    $display("[DUT] S=0x%08h  (s=%0d e=0x%02h m=0x%06h)  ov=%0d un=%0d",
             S_dut, get_sig(S_dut), get_exp(S_dut), get_man(S_dut), ov_dut, un_dut);
    $display(" DIFF: sign=%0d exp=%0d mant=%0d ov=%0d un=%0d  | #diff=%0d  ==> %s",
             ds, de, dm, dov, dun, diff_count, verdict);
    $display("--------------------------------------------------------------------------------");
  endtask

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int warn_cnt = 0;
  int fail_cnt = 0;
  int i;                 // loop index
  string verdict;        // "PASS"/"WARNING"/"FAIL"

  // Expected outputs
  logic [31:0] exp_s;
  logic        exp_ov, exp_un;

  // Per-field comparisons
  logic dut_sign, ref_sign;
  logic [7:0]  dut_exp,  ref_exp;
  logic [22:0] dut_mant, ref_mant;
  logic        differ_sign, differ_exp, differ_mant, differ_ov, differ_un;
  int          diff_count;

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Deterministic seed
    void'($urandom(32'hFEED_BEEF));

    for (i = 0; i < VECTORS; i++) begin
      // Random inputs
      i_32_a    = $urandom();
      i_32_b    = $urandom();
      i_add_sub = $urandom_range(0,1);
      #1;

      // Reference
      ref_fpu(i_32_a, i_32_b, i_add_sub, exp_s, exp_ov, exp_un);

      // Extract fields
      dut_sign = get_sig(o_32_s);  ref_sign = get_sig(exp_s);
      dut_exp  = get_exp(o_32_s);  ref_exp  = get_exp(exp_s);
      dut_mant = get_man(o_32_s);  ref_mant = get_man(exp_s);

      // Compare fields (use case-equality to be robust with X)
      differ_sign = (dut_sign !== ref_sign);
      differ_exp  = (dut_exp  !== ref_exp);
      differ_mant = (dut_mant !== ref_mant);
      differ_ov   = (o_ov_flag !== exp_ov);
      differ_un   = (o_un_flag !== exp_un);

      // Count differences
      diff_count = (differ_sign ? 1:0) +
                   (differ_exp  ? 1:0) +
                   (differ_mant ? 1:0) +
                   (differ_ov   ? 1:0) +
                   (differ_un   ? 1:0);

      // Verdict policy
      if (diff_count == 0) begin
        verdict = "PASS";
        pass_cnt++;
      end
      else if (!differ_sign && !differ_exp && (differ_mant || differ_ov || differ_un)) begin
        // Sign & exponent match -> tolerate rounding/flag differences
        verdict = "WARNING";
        warn_cnt++;
      end
      else if (diff_count >= 2) begin
        verdict = "FAIL";
        fail_cnt++;
      end
      else begin
        // Exactly one difference:
        // if that single diff is sign or exponent -> treat as FAIL (critical fields)
        if (differ_sign || differ_exp) begin
          verdict = "FAIL";
          fail_cnt++;
        end else begin
          verdict = "WARNING"; // single mantissa/flag diff
          warn_cnt++;
        end
      end

      // Print
      print_case(i, i_32_a, i_32_b, i_add_sub,
                 exp_s, exp_ov, exp_un,
                 o_32_s, o_ov_flag, o_un_flag,
                 verdict, diff_count,
                 differ_sign, differ_exp, differ_mant, differ_ov, differ_un);
    end

    // Summary
    $display("============================= SUMMARY =============================");
    $display("Total: %0d   PASS: %0d   WARNING: %0d   FAIL: %0d",
             VECTORS, pass_cnt, warn_cnt, fail_cnt);
    $display("==================================================================");

    $finish;
  end

endmodule
