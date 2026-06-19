/**
 * File              : top_dummy.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 08.04.2026
 * Last Modified Date: 08.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module top_dummy #(
    parameter WB_DATA_WIDTH = 16,
    parameter WB_ADDR_DIR = 2,
    parameter CLK_HZ = 100000000,
    parameter FREC_DISPLAY = 500
) (
    input wb_clk,
    input wb_rst,
    output [(WB_DATA_WIDTH>>2)-1:0] an,
    output [6:0] seg
);

  whisbone_if #(
      .DATA_WIDTH(WB_DATA_WIDTH),
      .ADDR_WIDTH(WB_ADDR_DIR)
  ) wb_impl (
      .wb_clk(wb_clk),
      .wb_rst(wb_rst)
  );

  wb_display #(
      .WB_DATA_WIDTH(WB_DATA_WIDTH),
      .WB_ADDR_DIR(WB_ADDR_DIR),
      .CLK_HZ(CLK_HZ),
      .FREC_DISPLAY(FREC_DISPLAY)
  ) wb_display_impl (
      .wb_slave(wb_impl),
      .an(an),
      .seg(seg)
  );

endmodule : top_dummy
