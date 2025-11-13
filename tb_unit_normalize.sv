`timescale 1ns/1ps

module tb_unit_normalize;

  // ===== DUT I/O =====
  logic         aos_alu;        // add:0, sub:1 (affects NORMAL zero detection)
  logic  [7:0]  i_exp;          // 0..254 for NORMAL, 255 for SPECIAL
  logic [27:0]  i_mant;
  logic         c_alu;          // case select: 1=case0 (right shift/+1), 0=case1 (normalize left)

  logic  [7:0]  o_exp;
  logic [27:0]  o_mant;
  logic         o_ov_fl;
  logic         o_un_fl;

  // ===== Instantiate DUT =====
  unit_normalize dut (
    .aos_alu (aos_alu),
    .i_exp   (i_exp),
    .i_mant  (i_mant),
    .c_alu   (c_alu),
    .o_exp   (o_exp),
    .o_mant  (o_mant),
    .o_ov_fl (o_ov_fl),
    .o_un_fl (o_un_fl)
  );

  // ===== Utility: leading-zero count for 28-bit =====
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
  logic         exp_o_ov;
  logic         exp_o_un;
  logic         exp_sel;        // expected sel = &i_exp
  int           n_cnt;          // expected n (LZC) used for prints

  // Loop temps (declare before statements)
  bit same;
  int idx;

  // Optional VCD dump
  initial begin
    `ifdef DUMP
      $dumpfile("tb_unit_normalize.vcd");
      $dumpvars(0, tb_unit_normalize);
    `endif
  end

  // Pretty header
  task automatic print_header();
    $display("===================================================================");
    $display("                 unit_normalize — Random Test (%0d)                ", VECTORS);
    $display("===================================================================");
  endtask

  // Pretty-print one vector (inputs / expected / DUT / verdict)
  task automatic print_sample(
    int            i_idx,
    logic          aos_t,
    logic          c_t,
    logic          sel_t,
    logic  [7:0]   exp_in_t,
    logic [27:0]   mant_in_t,
    int            n_t,
    logic  [7:0]   e_exp,
    logic [27:0]   m_exp,
    logic          ov_exp,
    logic          un_exp,
    logic  [7:0]   e_dut,
    logic [27:0]   m_dut,
    logic          ov_dut,
    logic          un_dut,
    bit            is_pass
  );
    $display("[IN ] #%0d  aos=%0d  c_alu=%0d  sel=%0d  i_exp=0x%02h  i_mant=0x%07h  (n=%0d)",
              i_idx, aos_t, c_t, sel_t, exp_in_t, mant_in_t, n_t);
    $display("[EXP]        o_exp=0x%02h  o_mant=0x%07h  o_ov_fl=%0d  o_un_fl=%0d",
              e_exp, m_exp, ov_exp, un_exp);
    $display("[DUT]        o_exp=0x%02h  o_mant=0x%07h  o_ov_fl=%0d  o_un_fl=%0d   ==> %s",
              e_dut, m_dut, ov_dut, un_dut, (is_pass ? "PASS" : "FAIL"));
    $display("-------------------------------------------------------------------");
  endtask

  // ===== Expected model (matches problem statement) =====
  // SPECIAL (sel=1): i_exp=255 always
  //   if c_alu=1: keep exp/mant, overflow=1, underflow=0
  //   if c_alu=0: n=LZC(mant), exp=255-n, mant<<=n, overflow=(exp==255), underflow=0
  //
  // NORMAL (sel=0): i_exp in [0..254]
  //   zero detection (only when c_alu=0):
  //     w0 = ~(|i_exp | |i_mant) ; w1 = ~(|i_mant)
  //     z  = (aos_alu ? w0 : w1)
  //     zero = (~c_alu) & z
  //   if zero: overflow=0, underflow=1, exp=0, mant=0
  //   else:
  //     case0 (c_alu=1): mant>>=1; exp=i_exp+1; overflow=(exp==255); underflow=0
  //     case1 (c_alu=0): n=LZC(mant); exp=max(i_exp-n,0); mant<<=n; underflow=(exp==0); overflow=0
  task automatic compute_expected_unit(
    input  logic        aos_i,
    input  logic        c_i,
    input  logic  [7:0] ie_i,
    input  logic [27:0] im_i,
    output logic  [7:0] e_o,
    output logic [27:0] m_o,
    output logic        ov_o,
    output logic        un_o,
    output logic        sel_o,
    output int          n_out
  );
    // ---- declare all locals first ----
    logic sel_local;
    // SPECIAL locals
    int            n_s;
    logic  [7:0]   e1_s;
    logic [27:0]   m1_s;
    logic          ov1_s;
    // NORMAL locals
    logic          w0, w1, z, zero;
    logic  [7:0]   e0_n;
    logic [27:0]   m0_n;
    logic          ov0_n;
    int            n_n;
    logic  [7:0]   e1_n;
    logic [27:0]   m1_n;
    logic          un1_n;

    // ---- compute sel ----
    sel_local = &ie_i; // 1 when ie_i==255
    sel_o     = sel_local;

    if (sel_local) begin
      // ===== SPECIAL =====
      if (c_i) begin
        // c_alu = 1: cannot normalize; keep exp/mant; overflow=1; underflow=0
        e_o  = 8'hFF;
        m_o  = im_i;
        ov_o = 1'b1;
        un_o = 1'b0;
        n_out = 0;
      end
      else begin
        // c_alu = 0: normalize left by n
        n_s  = lzc28(im_i);
        e1_s = 8'd255 - n_s[7:0];
        m1_s = im_i << n_s;
        ov1_s = (e1_s == 8'hFF); // overflow only if n==0
        e_o  = e1_s;
        m_o  = m1_s;
        ov_o = ov1_s;
        un_o = 1'b0;
        n_out = n_s;
      end
    end
    else begin
      // ===== NORMAL =====
      // zero detection (only active when c_alu=0)
      w0   = ~((|ie_i) | (|im_i)); // 1 when ie_i==0 and im_i==0
      w1   = ~(|im_i);             // 1 when mant==0
      z    = aos_i ? w0 : w1;
      zero = (~c_i) & z;

      if (zero) begin
        e_o  = 8'd0;
        m_o  = 28'd0;
        ov_o = 1'b0;
        un_o = 1'b1;
        n_out = 0;
      end
      else if (c_i) begin
        // case0: right shift, exp+1
        e0_n  = ie_i + 8'd1;     // ie_i in [0..254] => e0_n in [1..255]
        m0_n  = im_i >> 1;
        ov0_n = (e0_n == 8'd255);
        e_o   = e0_n;
        m_o   = m0_n;
        ov_o  = ov0_n;
        un_o  = 1'b0;
        n_out = 0;
      end
      else begin
        // case1: normalize left by n, saturating subtract for exp
        n_n  = lzc28(im_i);
        e1_n = (ie_i > n_n[7:0]) ? (ie_i - n_n[7:0]) : 8'd0;
        m1_n = im_i << n_n;
        un1_n = (e1_n == 8'd0);
        e_o  = e1_n;
        m_o  = m1_n;
        ov_o = 1'b0;    // no overflow in NORMAL case1
        un_o = un1_n;
        n_out = n_n;
      end
    end
  endtask

  // ===== Main stimulus =====
  initial begin
    print_header();

    // Reproducible seed
    void'($urandom(32'hDEAD_BEEF));

    for (idx = 0; idx < VECTORS; idx++) begin
      // Randomize: choose SPECIAL or NORMAL by picking i_exp accordingly
      if ($urandom_range(0,1)) begin
        // SPECIAL
        i_exp  = 8'hFF;
      end else begin
        // NORMAL
        i_exp  = $urandom_range(0, 254);
      end
      aos_alu = $urandom_range(0, 1);
      c_alu   = $urandom_range(0, 1);
      i_mant  = $urandom() & 28'hFFFFFFF; // 28 bits (7 hex digits)

      // Combinational settle
      #1;

      // Compute expected
      compute_expected_unit(aos_alu, c_alu, i_exp, i_mant,
                            exp_o_exp, exp_o_mant, exp_o_ov, exp_o_un,
                            exp_sel, n_cnt);

      // Compare (4 outputs)
      same = (o_exp   === exp_o_exp)  &&
             (o_mant  === exp_o_mant) &&
             (o_ov_fl === exp_o_ov)   &&
             (o_un_fl === exp_o_un);

      if (same) pass_cnt++; else fail_cnt++;

      // Print per-vector block
      print_sample(idx, aos_alu, c_alu, exp_sel, i_exp, i_mant, n_cnt,
                   exp_o_exp, exp_o_mant, exp_o_ov, exp_o_un,
                   o_exp,     o_mant,     o_ov_fl,  o_un_fl,
                   same);
    end

    // Summary
    $display("============== SUMMARY ==============");
    $display("Total: %0d   PASS: %0d   FAIL: %0d", VECTORS, pass_cnt, fail_cnt);
    $display("=====================================");

    $finish;
  end

endmodule
