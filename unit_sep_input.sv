module unit_sep_input (
    input       logic   [31:0]  A   ,   B   ,
    output      logic           S_A ,   S_B ,
    output      logic   [7:0]   E_A ,   E_B ,
    output      logic   [22:0]  M_A ,   M_B
);
assign S_A  =   A[31];
assign S_B  =   B[31];
assign E_A  =   A[30:23];
assign E_B  =   B[30:23];
assign M_A  =   A[22:0];
assign M_B  =   B[22:0];    
endmodule