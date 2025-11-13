module nor_case_1 (
    input logic [7:0] i_exp,
    output logic [7:0] o_exp,
    input logic [27:0] i_mant,
    output logic [27:0] o_mant,
    output logic underflow
//    output  logic overflow
);
logic [7:0] n;
leading_zero u0 (
    .i_mant     (i_mant),
    .o_cout     (n)
);
logic [27:0] mant;
SHLL u1 (
    .i_val      (i_mant),
    .i_sl_bit   (n),
    .o_val_sl   (mant)
);

logic [7:0] exp;
add_sub_8bit u2 (
    .A      (i_exp),
    .B      (n),
    .aos    (1'b1),
    .S      (exp),
    .Co     ()
);
// is exp = 0 ? (1 is yes)
logic ze;
assign ze = ~|exp; // ze = 1 -> underflow 



assign o_exp = exp;
assign o_mant = mant;
assign underflow = ze;
//assign overflow = zero ? 1'b0 : ov;

endmodule