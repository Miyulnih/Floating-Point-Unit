`timescale 1ns/1ps

module tb_spec_normalize;

  // ========= DUT I/O =========
  logic [7:0]   i_exp;
  logic         c_alu;
  logic [27:0]  i_mant;

  logic [7:0]   o_exp;
  logic [27:0]  o_mant;
  logic         o_overflow;

  // ========= Instantiate DUT =========
  spec_normalize dut (
    .i_exp      (i_exp),
    .c_alu      (c_alu),
    .i_mant     (i_mant),
    .o_exp      (o_exp),
    .o_mant     (o_mant),
    .o_overflow (o_overflow)
  );

  // ========= Utility: leading zero count for 28-bit =========
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

  // ========= Config / counters =========
  int N = 100;       // number of random vectors
  int pass_cnt = 0;
  int fail_cnt = 0;

  // Expected signals
  logic [7:0]   exp_o_exp;
  logic [27:0]  exp_o_mant;
  logic         exp_o_overflow;

  // Declare loop temps here (before any statements) to satisfy tools
  int n_cnt;
  bit same;

  // Optional waveform dump
  initial begin
    `ifdef DUMP
      $dumpfile("tb_spec_normalize.vcd");
      $dumpvars(0, tb_spec_normalize);
    `endif
  end

  task automatic print_header();
    $display("==============================================================");
    $display("        spec_normalize | Random Test (%0d vectors)            ", N);
    $display("==============================================================");
  endtask

  // Pretty print a single sample (inputs, expected, DUT, verdict)
  task automatic print_sample(
      int idx,
      logic         c_alu_t,
      logic [27:0]  mant_t,
      int           n_t,
      logic [7:0]   exp_e,
      logic [27:0]  exp_m,
      logic         exp_ovf,
      logic [7:0]   dut_e,
      logic [27:0]  dut_m,
      logic         dut_ovf,
      bit           is_pass
  );
    $display("[IN ] #%0d  c_alu=%0d  i_exp=0x%02h  i_mant=0x%07h  (n=%0d)",
              idx, c_alu_t, 8'hFF, mant_t, n_t);
    $display("[EXP]        o_exp=0x%02h  o_mant=0x%07h  o_overflow=%0d",
              exp_e, exp_m, exp_ovf);
    $display("[DUT]        o_exp=0x%02h  o_mant=0x%07h  o_overflow=%0d   ==> %s",
              dut_e, dut_m, dut_ovf, (is_pass ? "PASS" : "FAIL"));
    $display("--------------------------------------------------------------");
  endtask

  // Compute expected behavior per the provided specification
  task automatic compute_expected(
      input  logic        c_alu_i,
      input  logic [27:0] i_mant_i,
      output logic [7:0]  e_exp,
      output logic [27:0] m_exp,
      output logic        ov_exp,
      output int          n_out
  );
    logic zm;
    logic [7:0]  e1;
    logic [27:0] m0, m1;
    logic        ov1;
    int          n;

    zm = |i_mant_i;
    m0 = zm ? i_mant_i : 28'h0;

    n  = lzc28(i_mant_i);
    e1 = 8'd255 - n[7:0];
    m1 = i_mant_i << n;
    ov1 = (e1 == 8'hFF); // all-ones exponent after normalization

    if (c_alu_i) begin
      e_exp  = 8'd255;
      m_exp  = m0;
      ov_exp = 1'b1;
    end
    else begin
      e_exp  = e1;
      m_exp  = m1;
      ov_exp = ov1;
    end

    n_out = n;
  endtask

  // ========= Main stimulus =========
  initial begin
    print_header();

    // i_exp is fixed at 255 for all tests
    i_exp = 8'hFF;

    // Fixed seed for reproducibility
    void'($urandom(32'hA1B2C3D4));

    for (int i = 0; i < N; i++) begin
      // Randomize inputs
      c_alu  = $urandom_range(0, 1);
      i_mant = $urandom() & 28'hFFFFFFF; // 7 hex digits = 28 bits

      // Allow combinational settling
      #1;

      // Compute expected
      compute_expected(c_alu, i_mant, exp_o_exp, exp_o_mant, exp_o_overflow, n_cnt);

      // Compare
      same =
           (o_exp      === exp_o_exp)      &&
           (o_mant     === exp_o_mant)     &&
           (o_overflow === exp_o_overflow);

      if (same) pass_cnt++; else fail_cnt++;

      // Print sample
      print_sample(i, c_alu, i_mant, n_cnt,
                   exp_o_exp, exp_o_mant, exp_o_overflow,
                   o_exp, o_mant, o_overflow, same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", N, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
