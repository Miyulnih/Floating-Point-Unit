module add_sub_8bit (
    input  logic [7:0] A, B,
    input  logic       aos,
    output logic [7:0] S,
    output logic       Co
  );
  logic [7:0] n_B;

  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1)
    begin : gen_xor
      xor x(n_B[i], B[i], aos);
    end
  endgenerate

  CLA8bit as8 (
            .A  (A)   ,
            .B  (n_B) ,
            .Ci (aos),
            .S  (S)   ,
            .Co (Co)
          );
endmodule
