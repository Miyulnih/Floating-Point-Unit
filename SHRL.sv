module SHRL (
    input  logic [27:0] i_val,
    input  logic [7:0]  i_sr_bit,
    output logic [27:0] o_val_sr
  );
  logic [27:0] s1, s2, s3, s4, s5;
  logic        zero;

  assign zero     = (i_sr_bit >= 8'd28);

  assign s1       = i_sr_bit[0] ? { 1'b0,  i_val[27:1] } : i_val;
  assign s2       = i_sr_bit[1] ? { 2'b0,  s1   [27:2] } : s1;
  assign s3       = i_sr_bit[2] ? { 4'b0,  s2   [27:4] } : s2;
  assign s4       = i_sr_bit[3] ? { 8'b0,  s3   [27:8] } : s3;
  assign s5       = i_sr_bit[4] ? { 16'b0, s4   [27:16]} : s4;

  assign o_val_sr = zero        ?   28'b0                : s5;  // shift >=28
endmodule
