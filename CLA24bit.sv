module CLA24bit (
    input       logic   [23:0]   A, B,
    input       logic            Ci,
    output      logic   [23:0]   S,
    output      logic            Co
  );

  //1. Lookahead carry
  logic [5:0] p, g;
  logic       c1, c2, c3, c4, c5;

  CLGen6bit u0 (
              .Ci (Ci),
              .P (p),
              .G (g),
              .C1 (c1),
              .C2 (c2),
              .C3 (c3),
              .C4 (c4),
              .C5 (c5),
              .Co (Co)
            );
  //2. 24 bit adder
  logic [5:0] ci_blk;
  assign ci_blk = {c5, c4, c3, c2, c1, Ci};

  genvar i;
  generate
    for ( i = 0; i < 6; i = i + 1)
    begin : GEN_CLA4
      CLA4bit u1 (
                .A  ( A[4*i+3 : 4*i] ),
                .B  ( B[4*i+3 : 4*i] ),
                .Ci ( ci_blk[i] )     ,
                .S  ( S[4*i+3 : 4*i] ),
                .Pg ( p[i] )          ,
                .Gg ( g[i] )
              );
    end
  endgenerate
endmodule
