/**
 * File              : sdspi_wb.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 06.04.2025
 * Last Modified Date: 06.04.2025
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_sdspi #(
    parameter CLK_FQ_KHZ = 100000,
    parameter WB_ADDR_DIR = 8,
    parameter WB_DATA_WIDTH = 8,
    parameter OFFSET_ADDR = 1
) (
    input                                  wb_clk,
    input                                  wb_rst,
    //wishbone interface
    input        [$clog2(WB_ADDR_DIR)-1:0] wb_adr_i,
    input        [      WB_DATA_WIDTH-1:0] wb_dat_i,
    input                                  wb_we_i,
    input                                  wb_cyc_i,
    input                                  wb_stb_i,
    input        [ (WB_DATA_WIDTH>>3)-1:0] wb_sel_i,
    input        [                    2:0] wb_cti_i,
    input        [                    1:0] wb_bte_i,
    output logic                           wb_ack_o,
    output logic                           wb_err_o,
    output                                 wb_rty_o,
    output       [      WB_DATA_WIDTH-1:0] wb_dat_o,
    //spi signals
    input                                  miso,
    output                                 mosi,
    output                                 sclk,
    output                                 ss,

    output [ 3:0] debug_state,
    output [31:0] sdspi_debug
);

  logic
      sdspi_reset,
      sdspi_busy,
      sdspi_err,
      sdspi_r_block,
      sdspi_r_multi_block,
      sdspi_r_byte,
      sdspi_w_block,
      sdspi_w_byte;
  logic [31:0] sdspi_block_addr;
  logic [7:0] sdspi_data_out, sdspi_data_in;
  logic [4:0] sdspi_sclk_speed;

  sdspi_wb_bridge #(
      .CLK_FQ_KHZ(CLK_FQ_KHZ),
      .WB_ADDR_DIR(WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH),
      .OFFSET_ADDR(OFFSET_ADDR)
  ) bridge_inst (
      .wb_clk(wb_clk),
      .wb_rst(wb_rst),
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
      .sdspi_rst(sdspi_reset),
      .sdspi_busy(sdspi_busy),
      .sdspi_err(sdspi_err),
      .sdspi_r_block(sdspi_r_block),
      .sdspi_r_multi_block(sdspi_r_multi_block),
      .sdspi_r_byte(sdspi_r_byte),
      .sdspi_w_block(sdspi_w_block),
      .sdspi_w_byte(sdspi_w_byte),
      .sdspi_block_addr(sdspi_block_addr),
      .sdspi_data_out(sdspi_data_out),
      .sdspi_data_in(sdspi_data_in),
      .sdspi_sclk_speed(sdspi_sclk_speed),
      .sdspi_state(sdspi_debug[7:0]),
      .debug_state(debug_state)
  );

  sdspihost #(
      .CLK_FQ_KHZ(CLK_FQ_KHZ)
  ) sdspi_inst (
      .clk(wb_clk),
      .reset(sdspi_reset),
      .busy(sdspi_busy),
      .err(sdspi_err),
      .r_block(sdspi_r_block),
      .r_multi_block(sdspi_r_multi_block),
      .r_byte(sdspi_r_byte),
      .w_block(sdspi_w_block),
      .w_byte(sdspi_w_byte),
      .block_addr(sdspi_block_addr),
      .data_out(sdspi_data_out),
      .data_in(sdspi_data_in),
      .sclk_speed(sdspi_sclk_speed),
      .miso(miso),
      .mosi(mosi),
      .sclk(sclk),
      .ss(ss),
      .debug(sdspi_debug)
  );

endmodule
