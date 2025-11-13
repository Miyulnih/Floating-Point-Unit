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
  // Uses $bitstoshortreal and $shortrealtobits (no packed unions).
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

    e_ref = s_bits[30:23];
    // Flags per your spec (final exponent after rounding)
    ov_ref = (e_ref == 8'hFF);  // Inf/NaN
    un_ref = (e_ref == 8'h00);  // zero/subnormal
  endtask

  // ===== Pretty printing =====
  task automatic print_header();
    $display("================================================================================");
    $display("                                        FPU TB                                  ");
    $display("                      100 random add/sub | self-checking                        ");
    $display("     Expected flags: ov=(exp==255), un=(exp==0) based on final IEEE-754 result  ");
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
    bit            is_pass
  );
    $display("[IN ] #%0d  op=%0d  A=0x%08h  B=0x%08h", idx, op, A, B);
    $display("      A: s=%0d e=0x%02h m=0x%06h   B: s=%0d e=0x%02h m=0x%06h",
             get_sig(A), get_exp(A), get_man(A),
             get_sig(B), get_exp(B), get_man(B));
    $display("[EXP] S=0x%08h  (s=%0d e=0x%02h m=0x%06h)  ov=%0d un=%0d",
             S_exp, get_sig(S_exp), get_exp(S_exp), get_man(S_exp), ov_exp, un_exp);
    $display("[DUT] S=0x%08h  (s=%0d e=0x%02h m=0x%06h)  ov=%0d un=%0d  ==> %s",
             S_dut, get_sig(S_dut), get_exp(S_dut), get_man(S_dut), ov_dut, un_dut,
             (is_pass ? "PASS" : "FAIL"));
    $display("--------------------------------------------------------------------------------");
  endtask

  // ===== Config / bookkeeping =====
  localparam int VECTORS = 100;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int i;          // loop index
  bit same;       // compare result

  // Expected outputs
  logic [31:0] exp_s;
  logic        exp_ov, exp_un;

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Deterministic seed
    void'($urandom(32'hFEED_BEEF));

    // 100 random vectors (still includes many special patterns by chance)
    for (i = 0; i < VECTORS; i++) begin
      i_32_a    = $urandom();           // random 32-bit patterns
      i_32_b    = $urandom();
      i_add_sub = $urandom_range(0,1);  // 0 add, 1 sub
      #1;

      // Compute expected via reference shortreal
      ref_fpu(i_32_a, i_32_b, i_add_sub, exp_s, exp_ov, exp_un);

      // Compare (result + flags)
      same = (o_32_s   === exp_s)  &&
             (o_ov_flag === exp_ov) &&
             (o_un_flag === exp_un);

      if (same) pass_cnt++; else fail_cnt++;
      print_case(i, i_32_a, i_32_b, i_add_sub, exp_s, exp_ov, exp_un,
                 o_32_s, o_ov_flag, o_un_flag, same);
    end

    // Summary
    $display("================================ SUMMARY ================================");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=========================================================================");

    $finish;
  end

endmodule
