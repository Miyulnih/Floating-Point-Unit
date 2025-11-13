//====================================
//=            CHAT GPT              =
//====================================
module leading_zero (
    input logic [27:0] i_mant,
    output logic [7:0] o_cout
  );

  logic [27:0] s14, s7, s4, s2;
  logic [7:0]  c14, c7, c4, c2, c1;

  assign c14 = (i_mant[27:14] == 14'b0) ? 8'd14 : 8'd0;
  assign s14 = (i_mant[27:14] == 14'b0) ? {i_mant[13:0], 14'b0} : i_mant;

  assign c7  = (s14[27:21]    == 7'b0 ) ? 8'd7  : 8'd0;
  assign s7  = (s14[27:21]    == 7'b0 ) ? {s14[20:0], 7'b0}     : s14;

  assign c4  = (s7[27:24]     == 4'b0 ) ? 8'd4  : 8'd0;
  assign s4  = (s7[27:24]     == 4'b0 ) ? {s7[23:0], 4'b0}      : s7;

  assign c2  = (s4[27:26]     == 2'b0 ) ? 8'd2  : 8'd0;
  assign s2  = (s4[27:26]     == 2'b0 ) ? {s4[25:0], 2'b0}      : s4;

  assign c1  = (s2[27]        == 1'b0 ) ? 8'd1  : 8'd0;

  assign o_cout = c14 + c7 + c4 + c2 + c1; // 0..28
endmodule

//CHAT GPT
