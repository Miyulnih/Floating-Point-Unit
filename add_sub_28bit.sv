module add_sub_28bit (A, B, aos, S, Co);
  input     logic   [27:0]   A, B;
  input     logic            aos;
  output    logic   [27:0]   S;
  output    logic            Co;
  wire [27:0] n_B;
  //NOT B
  genvar i;
  generate
    for (i = 0; i < 28; i = i + 1)
    begin : gen_xor
      xor x(n_B[i], B[i], aos);
    end
  endgenerate
  // A - B when Ci = 1; A + B when Ci = 0
  CLA28bit u0(
             .A(A),
             .B (n_B),
             .Ci (aos),
             .S (S),
             .Co (Co)
           );
endmodule

