/**
 * File              : wb_display.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 08.04.2026
 * Last Modified Date: 08.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_display #(
    parameter WB_DATA_WIDTH = 16,
    parameter WB_ADDR_DIR = 2,
    parameter CLK_HZ = 100000000,
    parameter FREC_DISPLAY = 500
) (
    whisbone_if.slave wb_slave,
    output [(WB_DATA_WIDTH>>2)-1:0] an,
    output [6:0] seg
);

  logic display_din_w;
  logic [WB_DATA_WIDTH-1:0] display_reg_din;
  //wrapper
  display_wrapper #(
      .WB_ADDR_DIR  (WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH)
  ) bridge_impl (
      .wb_slave(wb_slave),
      //display interface
      .display_din(display_reg_din),
      //register data for display
      .display_din_w(display_din_w)
  );
  //register
  logic [WB_DATA_WIDTH-1:0] display_reg_dout;
  register #(
      .DATA_WIDTH(WB_DATA_WIDTH)
  ) display_din_reg (
      .clk(wb_slave.wb_clk),
      .cl(wb_slave.wb_rst),
      .w(display_din_w),
      .din(display_reg_din),
      .dout(display_reg_dout)
  );
  //display
  display #(
      .CLK_HZ(CLK_HZ),
      .FREC_DISPLAY(FREC_DISPLAY),
      .N(WB_DATA_WIDTH)
  ) display_impl (
      .clk(wb_slave.wb_clk),
      .rst(wb_slave.wb_rst),
      .din(display_reg_dout),
      .an (an),
      .seg(seg)
  );

endmodule : wb_display
