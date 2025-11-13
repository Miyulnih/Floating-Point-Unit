module nor_case_0 (
    input logic [7:0] i_exp,
    output logic [7:0] o_exp,
    input logic [27:0] i_mant,
    output logic [27:0] o_mant,
    output logic overflow
  );
  logic [7:0] exp;
  add_sub_8bit u0 (
                 .A      (i_exp),
                 .B      (8'd1),
                 .aos    (1'b0),
                 .S      (exp),
                 .Co     ()
               );
  assign o_exp = exp;
  assign overflow = &exp;
  assign o_mant = {1'b0, i_mant[27:1]}; //SHRL 1 bit
endmodule
