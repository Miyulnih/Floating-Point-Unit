module unit_exception_signal (
    input  logic        i_aos,
    input  logic        i_signA, i_signB,
    input  logic [7:0]  i_expA, i_expB,
    input  logic [22:0] i_mantA, i_mantB,
    output logic        e_mt,       // per test: 1 when expA==255 and expB==0 (ignore mantissas)
    output logic        spe_m,      // NaN mantissa flag for Inf±Inf
    output logic        spe_sig     // special-case selector (Inf/Zero combos)
);
  // IEEE-754 classifiers (used only for spe_sig/spe_m)
  wire a_is_inf  = (&i_expA) && (~|i_mantA);
  wire b_is_inf  = (&i_expB) && (~|i_mantB);
  wire a_is_zero = (~|i_expA) && (~|i_mantA);
  wire b_is_zero = (~|i_expB) && (~|i_mantB);

  // Special-case selector: {Inf&Inf} or {Inf&Zero} or {Zero&Inf}
  assign spe_sig = (a_is_inf & b_is_inf) | (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);

  // e_mt per your test contract: exponent-only decision
  assign e_mt = (&i_expA) & (~|i_expB);

  // NaN for Inf ± Inf:
  // ADD (i_aos=1): NaN when signs differ  (+Inf)+(-Inf) or (-Inf)+(+Inf)
  // SUB (i_aos=0): NaN when signs same   (+Inf)-(+Inf) or (-Inf)-(-Inf)
  wire signs_diff = i_signA ^ i_signB;
  wire nan_case   = (i_aos ? signs_diff : ~signs_diff) & (a_is_inf & b_is_inf);

  assign spe_m = nan_case;
endmodule
