module CLA28bit (
    input  logic [27:0] A, B,
    output logic [27:0] S   ,
    input  logic        Ci  ,
    output logic        Co
  );
  //============ Lookahead Carry =================
  logic [6:0] p;
  logic [6:0] g;
  logic c1, c2, c3, c4, c5, c6;
  CLGen7bit u0 (
              .Ci (Ci),
              .P (p),
              .G (g),
              .C1 (c1),
              .C2 (c2),
              .C3 (c3),
              .C4 (c4),
              .C5 (c5),
              .C6 (c6),
              .Co (Co)
            );
  //============== 28 bit adder ==================
  logic [6:0] ci_blk;
  assign ci_blk = {c6, c5, c4, c3, c2, c1, Ci};

  genvar i;
  generate
    for ( i = 0; i < 7; i = i + 1)
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
