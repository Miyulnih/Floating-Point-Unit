module spec_normalize (
    input logic [7:0]  i_exp,
    input logic        c_alu,
    input logic [27:0] i_mant,
    output logic [7:0] o_exp,
    output logic [27:0] o_mant,
    output logic        o_overflow
  //  output logic        o_un_fl
  );

  
  // c_alu = signal (1 for case 0; o for case 1)
  logic zm;
  assign zm = |i_mant; // zm =  0 when mantissa = 0

//1. CASE 0 (c_alu = 1): can not normalize -> overflow flag always 1
// mantissa =  0 -> overflow (inf) -> exp = 8d255, mant = 28h0  , overflow = 1
// mantissa #  0 -> overflow (NaN) -> exp = 8d255, mant = i_mant, overflow = 1

  logic [27:0] m0;
  assign m0 = zm ? i_mant : 28'h0;

//2. CASE 1 (c_alu = 0): need normalize -> overflow can be changed
logic [7:0] n;
leading_zero u0 (
  .i_mant   (i_mant),
  .o_cout   (n)
);

logic [7:0] e1;
add_sub_8bit u1 (
  .A      (i_exp),
  .B      (n),
  .aos    (1'b1), //1 is subtraction
  .S      (e1),
  .Co     ()
);
logic [27:0] m1;
SHLL u2 (
  .i_val      (i_mant),
  .i_sl_bit   (n),
  .o_val_sl   (m1)
);

logic ov1;
assign ov1 = &e1 ? 1'b1 : 1'b0;


//3. final output

  assign o_exp        =   c_alu   ?     8'd255    :   e1;
  assign o_mant       =   c_alu   ?     m0        :   m1;
  assign o_overflow   =   c_alu   ?     1'b1      :   ov1;


endmodule


