module CLGen4bit (
    input    logic Ci,
    input    logic [3:0] P, G,
    output   logic Pg, Gg, C1, C2, C3, Co
  );
  assign Pg = &P;
  assign Gg = G[3] | (P[3]&G[2]) | (P[3]&P[2]&G[1]) | (P[3]&P[2]&P[1]&G[0]);
  assign C1 = G[0] | (P[0] & Ci);
  assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Ci);
  assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Ci);
  assign Co = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) |
         (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & Ci);
endmodule
