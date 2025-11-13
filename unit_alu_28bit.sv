// TEST
module unit_alu_28bit (
    input       logic   [27:0]  augend, addend,
    input       logic           aos,
    output      logic   [27:0]  result,
    output      logic           c_alu
  );

  add_sub_28bit u0 (
                  .A      (augend),
                  .B      (addend),
                  .aos    (aos),
                  .S      (result),
                  .Co     (c_alu)
                );

endmodule
