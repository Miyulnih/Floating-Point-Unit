module CLA4bit(
    input [3:0] A, B,
    input Ci,
    output [3:0] S,
    output Pg, Gg
  );
  //================== CLA Generator ========================
  wire co, c1, c2, c3;
  wire p0, p1, p2, p3, g0, g1, g2, g3;

  CLGen4bit gen(
              .Ci(Ci),
              .P({p3, p2, p1, p0}),
              .G({g3, g2, g1, g0}),
              .Pg(Pg),
              .Gg(Gg),
              .C1(c1),
              .C2(c2),
              .C3(c3),
              .Co(co)
            );
  //================== CLA ADDER ============================
  CLA1bit u0(A[0],B[0],Ci, p0,g0,S[0]);
  CLA1bit u1(A[1],B[1],c1, p1,g1,S[1]);
  CLA1bit u2(A[2],B[2],c2, p2,g2,S[2]);
  CLA1bit u3(A[3],B[3],c3, p3,g3,S[3]);
endmodule
