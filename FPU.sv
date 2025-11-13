module FPU (
    input       logic       [31:0]      i_32_a,     i_32_b,
    input       logic                   i_add_sub,
    output      logic       [31:0]      o_32_s,
    output      logic                   o_ov_flag,  o_un_flag
  );
  //1. seperate input
  logic   [22:0]  ma, mb;
  logic   [7:0]   ea, eb;
  logic           sa, sb;
  unit_sep_input  u0 (
                    .A      (i_32_a),
                    .B      (i_32_b),
                    .S_A    (sa),
                    .S_B    (sb),
                    .E_A    (ea),
                    .E_B    (eb),
                    .M_A    (ma),
                    .M_B    (mb)
                  );

  //2. preprocess exception
  logic e_mt, spe_m, spe_sig;
  unit_exception_signal u1 (
                          .i_aos      (i_add_sub),
                          .i_signA    (sa),
                          .i_signB    (sb),
                          .i_expA     (ea),
                          .i_expB     (eb),
                          .i_mantA    (ma),
                          .i_mantB    (mb),
                          .e_mt       (e_mt),
                          .spe_m      (spe_m),
                          .spe_sig    (spe_sig)
                        );

  //3. preprocess exponent
  logic [7:0] e_pre, E_sub;
  logic       e_lt;
  unit_sel_exp u2 (
                 .ExpA       (ea),
                 .ExpB       (eb),
                 .o_Exp      (e_pre),
                 .E_sub      (E_sub),
                 .Ce_lt      (e_lt)
               );
  //4. preprocess mantisaa
  logic   [27:0]  augend, addend;
  logic           cm;
  unit_sel_aug_add u3 (
                     .Mant_A         (ma),
                     .Mant_B         (mb),
                     .E_sub          (E_sub),
                     .Ce             (e_lt),
                     .Augend         (augend),
                     .Addend         (addend),
                     .C_mant         (cm)
                   );

  //5. add/sub signal for alu
  logic aos_alu;
  unit_aos_alu    u4 (
                    .S_A        (sa),
                    .S_B        (sb),
                    .i_AoS      (i_add_sub),
                    .o_AoS      (aos_alu)
                  );
  //6. ALU 28 bit for mantissa
  logic  [27:0]   m_pre;
  logic           c_alu;
  unit_alu_28bit  u5 (
                    .augend     (augend),
                    .addend     (addend),
                    .aos        (aos_alu),
                    .result     (m_pre),
                    .c_alu      (c_alu)
                  );
  //7. normalize
  logic   [27:0]  m6;
  logic   [7:0]   e6;
  logic           ov6, un6;
  unit_normalize  u6 (
                    .aos_alu        (aos_alu),
                    .i_exp          (e_pre),
                    .i_mant         (m_pre),
                    .c_alu          (c_alu),
                    .o_exp          (e6),
                    .o_mant         (m6),
                    .o_ov_fl        (ov6),
                    .o_un_fl        (un6)
                  );
  //8. rounding
  logic   [22:0]  m7;
  logic   [7:0]   e7;
  logic           ov7;
  unit_rounding u7 (
                  .i_exp      (e6),
                  .i_mant     (m6),
                  .i_ov_fl    (ov6),
                  .i_un_fl    (un6),
                  .o_exp      (e7),
                  .o_mant     (m7),
                  .o_ov_fl    (ov7),
                  .o_un_fl    (o_un_flag)       //output
                );
  //9. final sign
  logic  eom, sign;
  assign eom = spe_sig ? e_mt : cm;
  unit_final_sign u8 (
                    .AoS        (i_add_sub),
                    .S_A        (sa),
                    .S_B        (sb),
                    .mt         (eom),
                    .Sign_rs    (sign)
                  );
  //10. pack final value
  //mux0
  logic [22:0] temp;
  assign temp = spe_m ? 23'h400000 : 23'h0;
  //mux1
  logic [22:0] mant;
  assign mant = spe_sig ? temp : m7;
  //mux2
  logic [7:0] exp;
  assign exp = spe_sig ? 8'hff : e7;
  //mux3
  assign o_ov_flag = spe_sig ? 1'b1 : ov7; //output

  unit_pack_value u9 (
                    .s_rs   (sign),
                    .e_rs   (exp),
                    .m_rs   (mant),
                    .result (o_32_s) //output
                  );
endmodule
