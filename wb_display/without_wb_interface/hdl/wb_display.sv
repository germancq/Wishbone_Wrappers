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
    input wb_clk,
    input wb_rst,
    output [(WB_DATA_WIDTH>>2)-1:0] an,
    output [6:0] seg,
    //wishbone interface
    input [$clog2(WB_ADDR_DIR)-1:0] wb_adr_i,
    input [WB_DATA_WIDTH-1:0] wb_dat_i,
    input wb_we_i,
    input wb_cyc_i,
    input wb_stb_i,
    input [(WB_DATA_WIDTH>>3)-1:0] wb_sel_i,
    input [2:0] wb_cti_i,
    input [1:0] wb_bte_i,
    output logic wb_ack_o,
    output logic wb_err_o,
    output wb_rty_o,
    output [WB_DATA_WIDTH-1:0] wb_dat_o
);

  logic display_din_w;
  logic [WB_DATA_WIDTH-1:0] display_reg_din;
  //wrapper
  display_wrapper #(
      .WB_ADDR_DIR  (WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH)
  ) bridge_impl (
      .wb_clk(wb_clk),
      .wb_rst(wb_rst),
      //wishbone interface
      .wb_adr_i(wb_adr_i),
      .wb_dat_i(wb_dat_i),
      .wb_we_i(wb_we_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_sel_i(wb_sel_i),
      .wb_cti_i(wb_cti_i),
      .wb_bte_i(wb_bte_i),
      .wb_ack_o(wb_ack_o),
      .wb_err_o(wb_err_o),
      .wb_rty_o(wb_rty_o),
      .wb_dat_o(wb_dat_o),
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
      .clk(wb_clk),
      .cl(wb_rst),
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
      .clk(wb_clk),
      .rst(wb_rst),
      .din(display_reg_dout),
      .an (an),
      .seg(seg)
  );

endmodule : wb_display
