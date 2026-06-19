/**
 * File              : top_dummy.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 09.04.2026
 * Last Modified Date: 09.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */


module top_dummy #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_DIR = 4,
    parameter BAUDIOS = 9600,
    parameter CLK_HZ = 100000000
) (
    input  wb_clk,
    input  wb_rst,
    input  rx,
    output tx
);

  whisbone_if #(
      .DATA_WIDTH(WB_DATA_WIDTH),
      .ADDR_WIDTH(WB_ADDR_DIR)
  ) wb_impl (
      .wb_clk(wb_clk),
      .wb_rst(wb_rst)
  );

  uart_wb #(
      .BAUDIOS(BAUDIOS),
      .CLK_HZ(CLK_HZ),
      .WB_ADDR_DIR(WB_ADDR_DIR),
      .WB_DATA_WIDTH(WB_DATA_WIDTH)
  ) wb_uart_impl (
      .wb_slave(wb_impl),
      .rx(rx),
      .tx(tx)
  );

endmodule
