module CLA1bit(
    input A, B, Ci,
    output P, G, S
  );
  assign G = A & B;
  assign P = A ^ B;
  assign S = P ^ Ci;
endmodule
