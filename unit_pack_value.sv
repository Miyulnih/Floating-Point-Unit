module unit_pack_value (
    input   logic   [22:0]      m_rs,
    input   logic   [7:0]       e_rs,
    input   logic               s_rs,
    output  logic   [31:0]      result
);
assign result = {s_rs,  e_rs,   m_rs};
endmodule