/**
 * File              : wb_gpio.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 18.02.2026
 * Last Modified Date: 26.11.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_gpio #(
    parameter WB_ADDR_DIR = 8,
    parameter WB_DATA_WIDTH = 32,
    parameter OFFSET_ADDR = 1,
    parameter N = 16
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
    //GPIO
    input        [                  N-1:0] gpio_in,
    output       [                  N-1:0] gpio_out
);


  localparam READ_GPIO = 0;
  localparam WRITE_GPIO = 1 * OFFSET_ADDR;

  genvar i;
  //register data from wishbone bus
  generate
    for (i = 0; i < 1; i = i + 1) begin
      register #(
          .DATA_WIDTH(WB_DATA_WIDTH)
      ) r_banks (
          .clk(wb_clk),
          .cl(wb_rst),
          .w(wb_adr_i == (i * OFFSET_ADDR) ? (wb_stb_i & wb_we_i & wb_cyc_i) : 0),
          .din(wb_dat_i),
          .dout(gpio_out)
      );
    end
  endgenerate

  logic r_data_w;
  //register data to wishbone bus
  register #(
      .DATA_WIDTH(WB_DATA_WIDTH)
  ) r_data (
      .clk(wb_clk),
      .cl(wb_rst),
      .w(r_data_w),
      .din(gpio_in),
      .dout(wb_dat_o)
  );

  localparam IDLE = 0;
  localparam END_OP = 4;

  logic [2:0] current_state, next_state;
  logic [31:0] aux;

  always_comb begin
    next_state = current_state;
    wb_err_o   = 0;
    wb_ack_o   = 0;
    r_data_w   = 0;

    case (current_state)
      IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          case (wb_adr_i)
            WRITE_GPIO: begin
              next_state = END_OP;
            end
            READ_GPIO: begin
              r_data_w   = 1;
              next_state = END_OP;
            end
            default: begin
              r_data_w   = 1;
              next_state = END_OP;
            end
          endcase
        end
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
