module renormalize_round (
    input       logic           i_un_fl,
    input       logic   [7:0]   i_exp,
    input       logic   [27:0]  i_mant,
    output      logic   [7:0]   o_exp,
    output      logic   [22:0]  o_mant,
    output      logic           o_ov_fl, o_un_fl
  );
  //1. rounding by add 1 to i_mant[27:4]
  logic     [23:0]    r_mant;
  logic               sel;
  CLA24bit    u0 (            
                .A      (i_mant[27:4]),
                .B      (24'h1),
                .Ci     (1'b0),
                .S      (r_mant),
                .Co     (sel)
              );
  //2. case 0: not change overflow/underflow flag
  logic un0;
  logic [7:0] e0;
  logic [22:0] m0;
  assign e0 = i_exp;
  assign m0 = r_mant [22:0];
  //assign m0 = r_mant [23:1]; //EDITED
  assign un0 = i_un_fl;

  //3. case 1: change overlow flag
  logic   [22:0]  m1;
  logic   [7:0]   e1;
  logic           un1;

  add_sub_8bit u1 (
                 .A      (i_exp),
                 .B      (8'd1),
                 .aos    (1'b0),
                 .S      (e1),
                 .Co     ()
               );

  assign m1   =   r_mant[23:1];
  // assign m1   =   r_mant[23:1];
  assign un1  =   1'b0;  //exponent was added by 1 (never 0)
  assign o_ov_fl = sel & (&e1);



  //4. select case (need renormalize or not)
  assign o_exp    =   sel     ?     e1      :       e0;
  assign o_mant   =   sel     ?     m1      :       m0;
  assign o_un_fl  =   sel     ?     un1     :       un0;


endmodule
