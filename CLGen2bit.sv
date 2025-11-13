module CLGen2bit (
    input Ci,
    input [1:0] P, G,
    output C1, Co
  );

  // Carry look-ahead
  assign C1 = G[0] | (P[0] & Ci);
  assign Co = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Ci);
endmodule
