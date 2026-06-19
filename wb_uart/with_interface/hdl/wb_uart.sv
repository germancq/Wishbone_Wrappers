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
          whisbone_if.slave wb_slave,
    input                   rx,
    output                  tx
);

  logic [7:0] data_tx, data_rx;
  logic tx_start, rx_active, tx_active, rx_done, tx_done;

  uart_wrapper #(
      .WB_ADDR_DIR  (WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH)
  ) bridge_impl (
      .wb_slave(wb_slave),
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
      .clk(wb_slave.wb_clk),
      .rst(wb_slave.wb_rst),
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
