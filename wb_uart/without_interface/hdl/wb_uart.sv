/**
 * File              : uart_wb.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 06.04.2026
 * Last Modified Date: 06.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_uart #(
    parameter BAUDIOS = 9600,
    parameter CLK_HZ = 100000000,
    parameter WB_ADDR_DIR = 8,
    parameter WB_DATA_WIDTH = 8
) (
    input                                  wb_clk,
    input                                  wb_rst,
    input                                  rx,
    output                                 tx,
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
    output       [      WB_DATA_WIDTH-1:0] wb_dat_o
);

  logic [7:0] data_tx, data_rx;
  logic tx_start, rx_active, tx_active, rx_done, tx_done;

  uart_wrapper #(
      .WB_ADDR_DIR  (WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH)
  ) bridge_impl (
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
      .uart_tx_start(tx_start),
      .uart_byte_tx(data_tx),
      .uart_byte_rx(data_rx),
      .uart_rx_active(rx_active),
      .uart_tx_active(tx_active),
      .uart_rx_done(rx_done),
      .uart_tx_done(tx_done)
  );

  uart #(
      .BAUDIOS(BAUDIOS),
      .CLK_HZ (CLK_HZ)
  ) uart_impl (
      .clk(wb_clk),
      .rst(wb_rst),
      .rx(rx),
      .tx(tx),
      .tx_start(tx_start),
      .tx_byte(data_tx),
      .rx_byte(data_rx),
      .rx_active(rx_active),
      .tx_active(tx_active),
      .tx_done(tx_done),
      .rx_done(rx_done)
  );
endmodule
