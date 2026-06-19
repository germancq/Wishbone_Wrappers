/**
 * File              : display_wrapper.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 08.04.2026
 * Last Modified Date: 08.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module display_wrapper #(
    parameter WB_ADDR_DIR   = 2,
    parameter WB_DATA_WIDTH = 8
) (
    whisbone_if.slave wb_slave,
    //display interface
    output logic [WB_DATA_WIDTH-1:0] display_din,
    //register data for display
    output logic display_din_w
);

  //intrucciones
  localparam DISPLAY_DATA = 0;

  //valores constantes
  assign wb_slave.wb_rty = 0;

  genvar i;
  //banco de registros desde el bus wishbone
  logic [WB_DATA_WIDTH-1:0] bank_register[WB_ADDR_DIR-1:0];
  generate
    for (i = 0; i < (WB_ADDR_DIR); i = i + 1) begin
      register #(
          .DATA_WIDTH(WB_DATA_WIDTH)
      ) r_banks (
          .clk(wb_slave.wb_clk),
          .cl(wb_slave.wb_rst),
          //si la direccion de instruccion corresponde y ademas esta activa
          //las señales de escritura almacenamos el dato
          .w(wb_slave.wb_adr == i ? (wb_slave.wb_stb & wb_slave.wb_we) : 0),
          .din(wb_slave.wb_dat),
          .dout(bank_register[i])
      );

    end
  endgenerate


  //registro hacia el bus wishbone
  //  logic r_data_w;
  //  logic [WB_DATA_WIDTH-1:0] wb_data;
  //  register #(
  //      .DATA_WIDTH(WB_DATA_WIDTH)
  //  ) r_data (
  //      .clk(wb_slave.wb_clk),
  //      .cl(wb_slave.wb_rst),
  //      .w(r_data_w),
  //      .din(wb_data),
  //      .dout(wb_slave.wb_rdt)
  //  );
  assign wb_slave.wb_rdt = 0;

  //especifico para el display
  assign display_din = bank_register[DISPLAY_DATA];


  //unidad de control
  localparam IDLE = 0;
  localparam DISPLAY_DATA_OP_0 = 1;
  localparam END_OP = 2;

  logic [1:0] current_state, next_state;

  always_comb begin
    next_state = current_state;

    wb_slave.wb_err = 0;
    wb_slave.wb_ack = 0;

    display_din_w = 0;

    case (current_state)
      IDLE: begin
        //si es un ciclo correcto de wishbone
        if (wb_slave.wb_stb & wb_slave.wb_cyc) begin
          case (wb_slave.wb_adr)
            DISPLAY_DATA: begin
              next_state = DISPLAY_DATA_OP_0;
            end
            default: begin
              next_state = IDLE;
            end
          endcase
        end
      end
      DISPLAY_DATA_OP_0: begin
        display_din_w = 1;
        next_state = END_OP;
      end
      END_OP: begin
        wb_slave.wb_ack = 1;
        if (wb_slave.wb_stb == 0) begin
          next_state = IDLE;
        end
      end
    endcase

  end


  always_ff @(posedge wb_slave.wb_clk) begin
    if (wb_slave.wb_rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end

  end

endmodule
