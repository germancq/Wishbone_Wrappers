/**
 * File              : uart_wrapper.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 06.04.2026
 * Last Modified Date: 06.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module uart_wrapper #(
    parameter WB_ADDR_DIR   = 8,
    parameter WB_DATA_WIDTH = 8
) (
    input wb_clk,
    input wb_rst,
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
    output [WB_DATA_WIDTH-1:0] wb_dat_o,
    //uart interface
    output logic uart_tx_start,
    output logic [7:0] uart_byte_tx,
    input [7:0] uart_byte_rx,
    input uart_rx_active,
    input uart_tx_active,
    input uart_rx_done,
    input uart_tx_done
);

  //intrucciones
  localparam UART_SEND_DATA = 0;
  localparam UART_RCV_DATA = 1;
  localparam UART_CTRL_DATA = 2;

  //valores constantes
  assign wb_rty_o = 0;

  genvar i;
  //banco de registros desde el bus wishbone
  logic [WB_DATA_WIDTH-1:0] bank_register[WB_ADDR_DIR-1:0];
  generate
    for (i = 0; i < (WB_ADDR_DIR); i = i + 1) begin
      register #(
          .DATA_WIDTH(WB_DATA_WIDTH)
      ) r_banks (
          .clk(wb_clk),
          .cl(wb_rst),
          //si la direccion de instruccion corresponde y ademas esta activa
          //las señales de escritura almacenamos el dato
          .w(wb_adr_i == i ? (wb_stb_i & wb_we_i) : 0),
          .din(wb_dat_i),
          .dout(bank_register[i])
      );

    end
  endgenerate


  //registro hacia el bus wishbone
  logic r_data_w;
  logic [WB_DATA_WIDTH-1:0] wb_data;
  register #(
      .DATA_WIDTH(WB_DATA_WIDTH)
  ) r_data (
      .clk(wb_clk),
      .cl(wb_rst),
      .w(r_data_w),
      .din(wb_data),
      .dout(wb_dat_o)
  );

  //especifico para la uart
  assign uart_byte_tx = bank_register[UART_SEND_DATA];


  //unidad de control
  localparam IDLE = 0;
  localparam SEND_BYTE_OP_0 = 1;
  localparam RECV_BYTE_OP_0 = 2;
  localparam CTRL_DATA_OP_0 = 3;
  localparam END_OP = 4;

  logic [2:0] current_state, next_state;

  always_comb begin
    next_state = current_state;

    wb_err_o = 0;
    wb_ack_o = 0;

    r_data_w = 0;

    uart_tx_start = 0;

    wb_data = uart_byte_rx;

    case (current_state)
      IDLE: begin
        //si es un ciclo correcto de wishbone
        if (wb_stb_i & wb_cyc_i) begin
          case (wb_adr_i)
            UART_SEND_DATA: begin
              next_state = SEND_BYTE_OP_0;
            end
            UART_RCV_DATA: begin
              next_state = RECV_BYTE_OP_0;
            end
            UART_CTRL_DATA: begin
              next_state = CTRL_DATA_OP_0;
            end
          endcase
        end
      end
      SEND_BYTE_OP_0: begin
        uart_tx_start = 1;
        if (uart_tx_done == 1) begin
          next_state = END_OP;
        end
      end
      RECV_BYTE_OP_0: begin
        if (uart_rx_done == 1) begin
          wb_data = uart_byte_rx;
          r_data_w = 1;
          next_state = END_OP;
        end
      end
      CTRL_DATA_OP_0: begin
        wb_data = {uart_tx_active, uart_rx_active};
        r_data_w = 1;
        next_state = END_OP;
      end
      END_OP: begin
        wb_ack_o = 1;
        if (wb_stb_i == 0) begin
          next_state = IDLE;
        end
      end
    endcase

  end


  always_ff @(posedge wb_clk) begin
    if (wb_rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end

  end

endmodule
