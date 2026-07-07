/**
 * File              : uart_wb.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 04.04.2025
 * Last Modified Date: 04.04.2025
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */
module wb_uart_fifo #(
    parameter CLK_HZ = 100000000,
    parameter BAUDIOS = 1000000,
    parameter FIFO_DEPTH = 16,
    parameter WB_ADDR_DIR = 8,
    parameter WB_DATA_WIDTH = 8,
    parameter OFFSET_ADDR = 1
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
    output       [      WB_DATA_WIDTH-1:0] wb_dat_o,
    output       [                    2:0] debug_state,
    output                                 debug_tx_active,
    output                                 debug_rx_active,
    output                                 debug_tx_empty,
    output                                 debug_rx_empty,
    output                                 debug_tx_full,
    output                                 debug_rx_full,
    output       [                    7:0] debug_data_tx,
    output                                 debug_pop_tx,
    output       [                    7:0] debug_data_rx,
    output       [                    7:0] debug_byte_rx,
    output       [                    2:0] debug_estado_rx,
    output       [                    2:0] debug_estado_tx
);

  logic [7:0] data_rx, data_tx;
  logic tx_start, rx_empty, tx_empty, rx_full, tx_full, rx_active, tx_active, read_byte;
  logic [2:0] estado_rx, estado_tx;
  logic [$clog2(FIFO_DEPTH):0] rx_bytes_available;
  assign debug_tx_active = tx_active;
  assign debug_rx_active = rx_active;
  assign debug_tx_full   = tx_full;
  assign debug_rx_full   = rx_full;
  assign debug_rx_empty  = rx_empty;
  assign debug_tx_empty  = tx_empty;
  assign debug_estado_rx = estado_rx;
  assign debug_estado_tx = estado_tx;
  assign debug_data_rx   = data_rx;

  uart_fifo_wb_bridge #(
      .CLK_HZ(CLK_HZ),
      .BAUDIOS(BAUDIOS),
      .FIFO_DEPTH(FIFO_DEPTH),
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
      .uart_tx_start(tx_start),
      .uart_read_byte(read_byte),
      .uart_byte_tx(data_tx),
      .uart_byte_rx(data_rx),
      .uart_rx_active(rx_active),
      .uart_tx_active(tx_active),
      .uart_rx_empty(rx_empty),
      .uart_rx_full(rx_full),
      .uart_rx_bytes_available(rx_bytes_available),
      .uart_tx_empty(tx_empty),
      .uart_tx_full(tx_full),
      .uart_estado_rx(estado_rx),
      .uart_estado_tx(estado_tx),
      .debug_state(debug_state)
  );

  uart_fifo #(
      .CLK_HZ(CLK_HZ),
      .BAUDIOS(BAUDIOS),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) uart_inst (
      .clk(wb_clk),
      .rst(wb_rst),
      .rx(rx),
      .tx(tx),
      .data_rx(data_rx),
      .byte_tx(data_tx),
      .tx_start(tx_start),
      .rx_empty(rx_empty),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      .tx_full(tx_full),
      .rx_bytes_available(rx_bytes_available),
      .rx_active(rx_active),
      .tx_active(tx_active),
      .read_byte(read_byte),
      .debug_pop_tx(debug_pop_tx),
      .debug_data_tx(debug_data_tx),
      .debug_byte_rx(debug_byte_rx)
  );

endmodule
