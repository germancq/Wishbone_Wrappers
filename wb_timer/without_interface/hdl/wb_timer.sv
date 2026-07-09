/**
 * File              : wb_timer.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 18.02.2026
 * Last Modified Date: 18.02.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_timer #(
    parameter WB_ADDR_DIR = 2,
    parameter WB_DATA_WIDTH = 32,
    parameter OFFSET_ADDR = 1,
    parameter N = 64
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
    output       [      WB_DATA_WIDTH-1:0] wb_dat_o
);

  logic counter_rst;
  logic [N-1:0] counter_dout;
  counter #(
      .DATA_WIDTH(N)
  ) timer (
      .clk (wb_clk),
      .rst (counter_rst),
      .up  (1'b1),
      .down(1'b0),
      .din (0),
      .dout(counter_dout)
  );

  localparam RST_TIMER = 0;
  localparam BASE_GET_TIMER = 1 * OFFSET_ADDR;

  //N and WB_DATA_WIDTH must be power of 2
  localparam NUM_GETS = N / WB_DATA_WIDTH;

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
          .w(wb_adr_i == (i * OFFSET_ADDR) ? (wb_stb_i & wb_we_i & wb_cyc_i) : 0),
          .din(wb_dat_i),
          .dout(bank_register[i])
      );
    end
  endgenerate

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

  localparam START_STATE = 0;
  localparam IDLE = 1;
  localparam RST_TIMER_OP_0 = 2;
  localparam GET_TIMER_OP_0 = 3;
  localparam END_OP = 4;

  logic [2:0] current_state, next_state;
  logic [31:0] aux;

  always_comb begin
    next_state = current_state;
    aux = (wb_adr_i / OFFSET_ADDR) - 1;
    wb_err_o = 0;
    wb_ack_o = 0;
    r_data_w = 0;
    counter_rst = 0;
    wb_data = counter_dout[WB_DATA_WIDTH-1:0];

    case (current_state)
      START_STATE: begin
        counter_rst = 1;
        next_state  = IDLE;
      end
      IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          case (wb_adr_i)
            RST_TIMER: next_state = RST_TIMER_OP_0;
            default:   next_state = GET_TIMER_OP_0;
          endcase
        end
      end
      RST_TIMER_OP_0: begin
        counter_rst = 1;
        next_state  = END_OP;
      end
      GET_TIMER_OP_0: begin
        aux = (wb_adr_i / OFFSET_ADDR) - 1;
        wb_data = counter_dout >> (aux * WB_DATA_WIDTH);
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
      current_state <= START_STATE;
    end else begin
      current_state <= next_state;
    end
  end


endmodule
