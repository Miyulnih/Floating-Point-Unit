module CLGen7bit (
    input  logic        Ci,
    input  logic [6:0]  P, G,
    output logic        C1, C2, C3, C4, C5, C6, Co
  );
  // carry
  assign C1 = G[0] | (P[0] & Ci);

  assign C2 = G[1]
         | (P[1] & G[0])
         | (P[1] & P[0] & Ci);

  assign C3 = G[2]
         | (P[2] & G[1])
         | (P[2] & P[1] & G[0])
         | (P[2] & P[1] & P[0] & Ci);

  assign C4 = G[3]
         | (P[3] & G[2])
         | (P[3] & P[2] & G[1])
         | (P[3] & P[2] & P[1] & G[0])
         | (P[3] & P[2] & P[1] & P[0] & Ci);

  assign C5 = G[4]
         | (P[4] & G[3])
         | (P[4] & P[3] & G[2])
         | (P[4] & P[3] & P[2] & G[1])
         | (P[4] & P[3] & P[2] & P[1] & G[0])
         | (P[4] & P[3] & P[2] & P[1] & P[0] & Ci);

  assign C6 = G[5]
         | (P[5] & G[4])
         | (P[5] & P[4] & G[3])
         | (P[5] & P[4] & P[3] & G[2])
         | (P[5] & P[4] & P[3] & P[2] & G[1])
         | (P[5] & P[4] & P[3] & P[2] & P[1] & G[0])
         | (P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & Ci);

  // Carry out
  assign Co = G[6]
         | (P[6] & G[5])
         | (P[6] & P[5] & G[4])
         | (P[6] & P[5] & P[4] & G[3])
         | (P[6] & P[5] & P[4] & P[3] & G[2])
         | (P[6] & P[5] & P[4] & P[3] & P[2] & G[1])
         | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0])
         | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & Ci);
endmodule
