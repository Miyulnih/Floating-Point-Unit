//DONE TEST
module unit_sel_exp (
    input  logic [7:0] ExpA, ExpB   ,
    output logic [7:0] o_Exp, E_sub ,
    output logic       Ce_lt
  );

  // compare exponent

  logic ce;
  compare_8bit u0 (
                 .A    (ExpA),
                 .B    (ExpB),
                 .e_lt (ce)
               );
  // swap exponent for subtraction

  logic [7:0] E_mt, E_lt;
  assign E_mt = ce ? ExpB : ExpA;
  assign E_lt = ce ? ExpA : ExpB;
  assign o_Exp = E_mt; // chose the larger exponent

  // subtraction for shift mantissa
  logic temp;
  add_sub_8bit u1 (
                 .A (E_mt),
                 .B (E_lt),
                 .aos (1'b1), // in case subtracion
                 .S (E_sub),
                 .Co (temp)
               );

  assign Ce_lt = ce;
endmodule
