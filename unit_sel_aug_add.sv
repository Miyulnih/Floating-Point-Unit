//DONE TEST
module unit_sel_aug_add (
    input  logic [22:0] Mant_A, Mant_B,
    input  logic [7:0]  E_sub,
    input  logic        Ce, //Ce = 1 when A < B; Ce = 0 when A >= B
    output logic [27:0] Augend, Addend,
    output logic        C_mant // C_mant = 1 when define a larger value of mantissa
  );

  //1. extend from 23 bits to 28 bits
  logic [27:0] M_A, M_B;

  assign M_A = {1'b1, Mant_A[22:0], 4'b0000};

  assign M_B = {1'b1, Mant_B[22:0], 4'b0000};

  //2. select mantissa had smaller exponent for SR process

  logic [27:0] M_em, M_el;
  assign M_em = Ce    ?   M_B :   M_A; // more than
  assign M_el = Ce    ?   M_A :   M_B; // less than

  //3. SR the mantissa which had smaller exponent



  logic [27:0] M_sr;
  SHRL u0 (
         .i_val      (M_el),
         .i_sr_bit   (E_sub),
         .o_val_sr   (M_sr)
       );

  //4. compare to find which mantissa has the larger value
  logic sel;
  compare_28bit u1 (
                  .A      (M_em),
                  .B      (M_sr),
                  .m_mt   (sel)
                );

  //5. choose the larger value as Augend, the smaller as Addend
  assign Augend   =   sel     ?   M_em    :   M_sr;
  assign Addend   =   sel     ?   M_sr    :   M_em;

  //6. C_mant output (C_mant = 1 when VALUE of A > B)
  assign C_mant = sel;

endmodule

