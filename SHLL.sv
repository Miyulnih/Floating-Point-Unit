module SHLL (
    input  logic [27:0] i_val,
    input  logic [7:0]  i_sl_bit,
    output logic [27:0] o_val_sl
  );
  logic [27:0] s1, s2, s3, s4, s5;
  logic        zero;

  assign zero = (i_sl_bit >= 8'd28);

  assign s1 = i_sl_bit[0] ? { i_val[26:0],  1'b0 } : i_val;
  assign s2 = i_sl_bit[1] ? { s1   [25:0],  2'b0 } : s1;
  assign s3 = i_sl_bit[2] ? { s2   [23:0],  4'b0 } : s2;
  assign s4 = i_sl_bit[3] ? { s3   [19:0],  8'b0 } : s3;
  assign s5 = i_sl_bit[4] ? { s4   [11:0], 16'b0 } : s4;

  assign o_val_sl = zero ? 28'b0 : s5;
endmodule
