//TEST
module nor_normalize (
    input   logic           aos_alu, //add: 0; sub: 1
    input   logic [7:0]     i_exp,
    output  logic [7:0]     o_exp,
    input   logic [27:0]    i_mant,
    output  logic [27:0]    o_mant,
    input   logic           c_alu,
    output  logic           o_overflow,
    output  logic           o_underflow
  );
  // zero signal in case 2 operands have the same value execute subtraction

  logic z, zero;
  logic w0, w1;
  assign w0 = ~((|i_exp)|(|i_mant));
  assign w1 = ~(|i_mant);

  assign z = aos_alu ? w0  :  w1; 
  assign zero = ~c_alu & z;



  logic ov0;
  logic [7:0] e0;
  logic [27:0] m0;
  nor_case_0 u0 (
               .i_exp      (i_exp),
               .i_mant     (i_mant),
               .o_exp      (e0),
               .o_mant     (m0),
               .overflow   (ov0)
             );

  logic un1, ov1;
  logic [7:0] e1;
  logic [27:0] m1;
  nor_case_1 u1 (
               .i_exp      (i_exp),
               .i_mant     (i_mant),
               .o_exp      (e1),
               .o_mant     (m1),
               .underflow  (un1)

             );

  logic [7:0] exp;
  logic [27:0] mant;
  assign exp = c_alu ? e0 : e1 ;
  assign mant = c_alu ? m0 : m1 ;


  assign o_overflow  = zero ? 1'b0 : (c_alu ? ov0 : 1'b0);
  assign o_underflow = zero ? 1'b1  : un1;
  assign o_exp       = zero ? 8'b0  : exp;
  assign o_mant      = zero ? 28'b0 : mant;

endmodule
