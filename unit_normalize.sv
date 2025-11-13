//DONE TEST
module unit_normalize (
    input   logic           aos_alu,   // EDITED HERE !!!
    input   logic   [7:0]   i_exp,
    input   logic   [27:0]  i_mant,
    input   logic           c_alu,
    output  logic   [7:0]   o_exp,
    output  logic   [27:0]  o_mant,
    output  logic           o_ov_fl,
    output  logic           o_un_fl
  );
  logic sel; //sigal for normal or special case
   assign sel = &i_exp; // special case when exp = 255 (sel = 1)

  logic no_ov, no_un;
  logic [7:0] no_e;
  logic [27:0] no_m;
  nor_normalize u0 (
                  .i_exp       (i_exp),
                  .i_mant      (i_mant),
                  .aos_alu     (aos_alu), // EDITED HERE !!!
                  .c_alu       (c_alu),
                  .o_exp       (no_e),
                  .o_mant      (no_m),
                  .o_overflow  (no_ov),
                  .o_underflow (no_un)
                );

  logic spe_ov;
  logic [7:0] spe_e;
  logic [27:0] spe_m;
  spec_normalize u1 (
                   .i_exp          (i_exp),
                   .i_mant         (i_mant),
                   .c_alu          (c_alu),
                   .o_exp          (spe_e),
                   .o_mant         (spe_m),
                   .o_overflow     (spe_ov)
                   //.o_un_fl        (spe_un)
                 );

  assign o_exp    =   sel     ?   spe_e    :   no_e;
  assign o_mant   =   sel     ?   spe_m    :   no_m;
  assign o_ov_fl  =   sel     ?   spe_ov   :   no_ov;
  assign o_un_fl  =   sel     ?   1'b0     :   no_un; //EDITED

endmodule
