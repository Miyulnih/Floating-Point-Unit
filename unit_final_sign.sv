//DONE TEST
module unit_final_sign (
    input   logic AoS, S_A, S_B, mt,
    output  logic Sign_rs
  );
  logic w1, w2, w3, w4;
  assign w1 = S_B & ~(mt);
  assign w2 = S_B | mt;
  assign w3 = ~(S_B) & mt;
  assign w4 = ~(S_B) | mt;

  assign Sign_rs = AoS ? (S_A ? w4 : w3) : (S_A ? w2 : w1);

endmodule
