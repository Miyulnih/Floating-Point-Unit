//TEST
module unit_aos_alu(
    input   logic S_A, S_B, i_AoS,
    output  logic o_AoS
  );
  logic w;
  xor g1 (w       , S_A   , S_B);
  xor g2 (o_AoS   , i_AoS , w);
endmodule
