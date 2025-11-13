//DONE TEST
module unit_rounding (
    input   logic   [7:0]   i_exp,
    input   logic   [27:0]  i_mant,
    input   logic           i_ov_fl, i_un_fl,
    output  logic   [7:0]   o_exp,
    output  logic   [22:0]  o_mant,
    output  logic           o_ov_fl, o_un_fl
  );
  //1. rounding signal (sig = 0 -> in = out; sig = 1 -> execute rounding process)
  // execute rounding process when enable renormalize and round up

  // ================ enable renormalize =================
  logic en;
  assign en = ~i_ov_fl;
  // ================== round up signal ==================
  logic r_up;
  assign r_up = i_mant[4] ? i_mant[3] : (i_mant[3] & |i_mant[2:0]);

  //assign r_up = i_mant[3] & (i_mant[4] | |i_mant[2:0]);


  logic sel;        //sig
  assign sel = en & r_up;

  //2. case 0: sel (sig) = 0
  logic [7:0] e0;
  logic [22:0] m0;

  assign e0 = i_exp;
  assign m0 = i_mant[26:4];

  //3. case 1: sel (sig) = 1
  logic [7:0] e1;
  logic [22:0] m1;
  logic ov1, un1;
  renormalize_round u0 (
                      .i_un_fl    (i_un_fl),
                      .i_exp      (i_exp),
                      .i_mant     (i_mant),
                      .o_exp      (e1),
                      .o_mant     (m1),
                      .o_ov_fl    (ov1),
                      .o_un_fl    (un1)
                    );
  //4. select mode
  assign o_exp    =   sel     ?   e1    :   e0;
  assign o_mant   =   sel     ?   m1    :   m0;
  assign o_ov_fl  =   sel     ?   ov1   :   i_ov_fl;
  assign o_un_fl  =   sel     ?   un1   :   i_un_fl;

endmodule
