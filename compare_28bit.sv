//====================================
//=            CHAT GPT              =
//====================================
module compare_28bit (
    input  logic [27:0] A, B,
    output logic        m_mt  // 1 when A > B (unsigned)
);
  // LOD-style highest-different-bit comparator with parallel-prefix OR
  // Depth ~ O(log2(WIDTH)) for good timing on ASIC/FPGA

  localparam int WIDTH  = 28;
  localparam int STAGES = (WIDTH > 1) ? $clog2(WIDTH) : 1;

  // 1) Bitwise difference (continuous assign; avoids time-0 init pitfall)
  logic [WIDTH-1:0] diff;
  assign diff = A ^ B;

  // Reverse 'diff' so we can build an inclusive prefix-OR from the LSB side
  logic [WIDTH-1:0] r0;
  generate
    for (genvar i = 0; i < WIDTH; i++) begin : GEN_REV_FWD
      assign r0[i] = diff[WIDTH-1-i];
    end
  endgenerate

  // 2) Parallel prefix OR (inclusive): pre[STAGES] holds OR of r0[0..i]
  logic [WIDTH-1:0] pre [0:STAGES];
  assign pre[0] = r0;

  generate
    for (genvar s = 0; s < STAGES; s++) begin : GEN_PREFIX
      localparam int DIST = (1 << s);
      for (genvar i = 0; i < WIDTH; i++) begin : GEN_PREFIX_CELL
        if (i >= DIST)
          assign pre[s+1][i] = pre[s][i] | pre[s][i-DIST];
        else
          assign pre[s+1][i] = pre[s][i];
      end
    end
  endgenerate

  // Convert inclusive prefix to exclusive prefix (shift right by 1; index 0 = 0)
  logic [WIDTH-1:0] prefix_excl;
  assign prefix_excl[0] = 1'b0;
  generate
    for (genvar i = 1; i < WIDTH; i++) begin : GEN_EXCL
      assign prefix_excl[i] = pre[STAGES][i-1];
    end
  endgenerate

  // Reverse back: higher_or[i] = OR of diff[k] for all k > i (i.e., higher bits)
  logic [WIDTH-1:0] higher_or;
  generate
    for (genvar i = 0; i < WIDTH; i++) begin : GEN_REV_BACK
      assign higher_or[i] = prefix_excl[WIDTH-1-i];
    end
  endgenerate

  // 3) One-hot mask at the highest differing bit
  logic [WIDTH-1:0] is_first;
  assign is_first = diff & ~higher_or;

  // 4) A > B if, at that bit, A=1 and B=0
  logic [WIDTH-1:0] a_gt_b_bit;
  assign a_gt_b_bit = A & ~B;

  logic [WIDTH-1:0] cand;
  assign cand = is_first & a_gt_b_bit;

  // Final OR (synth will balance this reduction tree)
  assign m_mt = |cand;

endmodule
