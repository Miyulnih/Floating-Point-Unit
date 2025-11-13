module CLA8bit(
    input   logic [7:0] A, B,
    output  logic [7:0] S,
    input   logic       Ci,
    output  logic       Co
  );
  logic [1:0] c_i;
  logic [1:0] p, g;
  logic c1;
  assign c_i = {c1, Ci};
  //============ Lookahead Carry ===================
  CLGen2bit u0 (
              .Ci(Ci),
              .P(p),
              .G(g),
              .C1(c1),
              .Co(Co)
            );

  //=================== Adder =======================
  genvar i;
  generate
    for ( i = 0; i < 2; i = i + 1)
    begin : GEN_CLA4
      CLA4bit u1 (
                .A  ( A[4*i+3 : 4*i] ),
                .B  ( B[4*i+3 : 4*i] ),
                .Ci ( c_i[i] )     ,
                .S  ( S[4*i+3 : 4*i] ),
                .Pg ( p[i] )          ,
                .Gg ( g[i] )
              );
    end
  endgenerate

endmodule
