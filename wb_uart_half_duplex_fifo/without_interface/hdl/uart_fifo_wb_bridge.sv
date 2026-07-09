/**
 * File              : uart_wb_bridge.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 04.04.2025
 * Last Modified Date: 04.04.2025
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */
module uart_fifo_wb_bridge #(
    parameter CLK_HZ = 1000000,
    parameter BAUDIOS = 1000000,
    parameter FIFO_DEPTH = 16,
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
    //uart_fifo interface
    output logic                           uart_tx_start,
    output logic                           uart_read_byte,
    output logic [                    7:0] uart_byte_tx,
    input        [                    7:0] uart_byte_rx,
    input                                  uart_rx_active,
    input                                  uart_tx_active,
    input                                  uart_rx_empty,
    input                                  uart_rx_full,
    input        [                    3:0] uart_rx_bytes_available,
    input                                  uart_tx_empty,
    input                                  uart_tx_full,
    input        [                    2:0] uart_estado_rx,
    input        [                    2:0] uart_estado_tx,
    output       [                    2:0] debug_state

);

  localparam SEND_DATA = 0;
  localparam RCV_DATA = 1 * OFFSET_ADDR;
  localparam CTRL_UART = 2 * OFFSET_ADDR;  //[bytes in rx fifo, [3:0] bytes in tx]

  //cte values
  assign wb_rty_o = 0;

  logic [WB_DATA_WIDTH-1:0] bank_register[WB_ADDR_DIR-1:0];

  genvar i;
  //register data from wishbone bus
  generate
    for (i = 0; i < (WB_ADDR_DIR); i = i + 1) begin
      register #(
          .DATA_WIDTH(WB_DATA_WIDTH)
      ) r_banks (
          .clk(wb_clk),
          .cl(wb_rst),
          .w(wb_adr_i == (i * OFFSET_ADDR) ? (wb_stb_i & wb_we_i) : 0),
          .din(wb_dat_i),
          .dout(bank_register[i])
      );
    end
  endgenerate



  assign uart_byte_tx = bank_register[SEND_DATA];


  logic r_data_w;
  logic [WB_DATA_WIDTH-1:0] wb_data;
  //register data to wishbone bus
  register #(
      .DATA_WIDTH(WB_DATA_WIDTH)
  ) r_data (
      .clk(wb_clk),
      .cl(wb_rst),
      .w(r_data_w),
      .din(wb_data),
      .dout(wb_dat_o)
  );


  //control unit
  localparam START_STATE = 0;
  localparam IDLE = 1;
  localparam SEND_BYTE_OP_0 = 2;
  localparam RECV_BYTE_OP_0 = 3;
  localparam RECV_BYTE_OP_1 = 4;
  localparam CTRL_UART_OP_0 = 5;
  localparam END_OP = 6;

  logic [2:0] current_state, next_state;
  assign debug_state = current_state;

  always_comb begin

    wb_err_o = 0;
    wb_ack_o = 0;

    r_data_w = 0;

    uart_tx_start = 0;
    uart_read_byte = 0;

    wb_data = uart_byte_rx;

    next_state = current_state;

    case (current_state)
      START_STATE: begin
        next_state = IDLE;
      end
      IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          case (wb_adr_i)
            SEND_DATA: next_state = SEND_BYTE_OP_0;
            RCV_DATA:  next_state = RECV_BYTE_OP_0;
            CTRL_UART: next_state = CTRL_UART_OP_0;
            default:   next_state = END_OP;
          endcase
        end
      end
      SEND_BYTE_OP_0: begin
        if (uart_tx_full == 0) begin
          next_state = END_OP;
          uart_tx_start = 1;
        end
      end
      RECV_BYTE_OP_0: begin
        if (uart_rx_empty == 0) begin
          uart_read_byte = 1;
          //wb_data = uart_byte_rx;
          //r_data_w = 1;
          next_state = RECV_BYTE_OP_1;
        end
      end
      RECV_BYTE_OP_1: begin
        wb_data = uart_byte_rx;
        r_data_w = 1;
        next_state = END_OP;
      end
      CTRL_UART_OP_0: begin
        wb_data = {uart_tx_active, uart_tx_empty, uart_rx_bytes_available};
        r_data_w = 1;
        next_state = END_OP;
      end
      END_OP: begin
        wb_ack_o = 1;
        if (wb_stb_i == 0) begin
          next_state = IDLE;
        end
      end
      default: begin
        wb_err_o = 1;
      end
    endcase
  end

  always_ff @(posedge wb_clk) begin
    if (wb_rst) begin
      current_state <= START_STATE;
    end else begin
      current_state <= next_state;
    end

  end

endmodule
