/**
 * File              : sdspi_wb_bridge.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 06.04.2025
 * Last Modified Date: 06.04.2025
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */
module sdspi_wb_bridge #(
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
    output                                 wb_err_o,
    output                                 wb_rty_o,
    output       [      WB_DATA_WIDTH-1:0] wb_dat_o,
    //sdspihost interface
    output logic                           sdspi_rst,
    input                                  sdspi_busy,
    input                                  sdspi_err,
    output logic                           sdspi_r_block,
    output logic                           sdspi_r_multi_block,
    output logic                           sdspi_r_byte,
    output logic                           sdspi_w_block,
    output logic                           sdspi_w_byte,
    output       [                   31:0] sdspi_block_addr,
    input        [                    7:0] sdspi_data_out,
    output       [                    7:0] sdspi_data_in,
    output       [                    4:0] sdspi_sclk_speed,
    input        [                    7:0] sdspi_state,

    output [4:0] debug_state
);

  localparam SET_ADDRESS = 0;
  localparam WRITE_BYTE = 1 * OFFSET_ADDR;
  localparam READ_BYTE = 2 * OFFSET_ADDR;
  localparam SET_SPEED = 3 * OFFSET_ADDR;
  localparam STOP_READ = 5 * OFFSET_ADDR;
  localparam STOP_WRITE = 6 * OFFSET_ADDR;
  localparam STOP = 4 * OFFSET_ADDR;  //stop read or write operation in block sd

  assign wb_rty_o = 1;
  assign wb_err_o = sdspi_err;

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
          .w(wb_adr_i == i ? (wb_stb_i & wb_we_i & wb_cyc_i) : 0),
          .din(wb_dat_i),
          .dout(bank_register[i])
      );
    end
  endgenerate



  assign sdspi_block_addr = bank_register[SET_ADDRESS];
  assign sdspi_data_in = bank_register[WRITE_BYTE];
  assign sdspi_sclk_speed = bank_register[SET_SPEED];


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


  logic sdspi_r_multi_block_cl;
  logic sdspi_r_multi_block_w;
  register #(
      .DATA_WIDTH(1)
  ) r_sdspi_r_multi_block (
      .clk(wb_clk),
      .cl(sdspi_r_multi_block_cl),
      .w(sdspi_r_multi_block_w),
      .din(1'b1),
      .dout(sdspi_r_multi_block)
  );
  //control unit
  localparam START_STATE = 0;
  localparam IDLE = 1;
  localparam END_OP = 2;
  localparam SET_ADDRESS_OP_0 = 3;
  localparam WRITE_BYTE_OP_0 = 4;
  localparam WRITE_BYTE_OP_1 = 5;
  localparam WRITE_BYTE_OP_2 = 6;
  localparam WRITE_BYTE_OP_3 = 7;
  localparam READ_BYTE_OP_0 = 8;
  localparam READ_BYTE_OP_1 = 9;
  localparam READ_BYTE_OP_2 = 10;
  localparam READ_BYTE_OP_3 = 11;
  localparam SET_SPEED_OP_0 = 12;
  localparam STOP_READ_OP_0 = 15;
  localparam STOP_READ_OP_1 = 16;
  localparam STOP_READ_OP_2 = 17;
  localparam STOP_WRITE_OP_0 = 18;
  localparam STOP_WRITE_OP_1 = 19;

  localparam STOP_OP_0 = 13;
  localparam STOP_OP_1 = 14;

  logic [4:0] current_state, next_state;
  assign debug_state = current_state;

  always_comb begin

    wb_ack_o = 0;

    r_data_w = 0;

    wb_data = sdspi_data_out;

    sdspi_rst = 0;
    sdspi_r_multi_block_w = 0;
    sdspi_r_multi_block_cl = 0;
    sdspi_w_block = 0;
    sdspi_w_byte = 0;
    sdspi_r_block = 0;
    sdspi_r_byte = 0;

    next_state = current_state;

    case (current_state)
      START_STATE: begin
        sdspi_rst = 1;
        sdspi_r_multi_block_cl = 1;
        next_state = IDLE;
      end
      IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          case (wb_adr_i)
            SET_ADDRESS: next_state = SET_ADDRESS_OP_0;
            WRITE_BYTE: next_state = WRITE_BYTE_OP_0;
            READ_BYTE: next_state = READ_BYTE_OP_0;
            SET_SPEED: next_state = SET_SPEED_OP_0;
            STOP_READ: next_state = STOP_READ_OP_0;
            STOP_WRITE: next_state = STOP_WRITE_OP_0;
            STOP: next_state = STOP_OP_0;
            default: next_state = END_OP;
          endcase
        end
      end
      SET_ADDRESS_OP_0: begin
        if (sdspi_busy == 0) begin
          next_state = END_OP;
        end
      end
      WRITE_BYTE_OP_0: begin
        if (sdspi_busy == 0) begin
          sdspi_w_block = 1;
          next_state = WRITE_BYTE_OP_1;
        end
      end
      WRITE_BYTE_OP_1: begin
        sdspi_w_block = 1;
        if (sdspi_busy == 0) begin
          next_state = WRITE_BYTE_OP_2;
        end
      end
      WRITE_BYTE_OP_2: begin
        sdspi_w_block = 1;
        sdspi_w_byte = 1;
        next_state = WRITE_BYTE_OP_3;

      end
      WRITE_BYTE_OP_3: begin
        sdspi_w_block = 1;
        if (sdspi_busy == 0) begin
          next_state = END_OP;
        end
      end
      READ_BYTE_OP_0: begin
        sdspi_r_multi_block_w = 1;
        if (sdspi_busy == 0) begin
          next_state = READ_BYTE_OP_1;
        end
      end
      READ_BYTE_OP_1: begin
        if (sdspi_busy == 0) begin
          next_state = READ_BYTE_OP_2;
        end
      end
      READ_BYTE_OP_2: begin
        sdspi_r_byte = 1;
        next_state   = READ_BYTE_OP_3;
      end
      READ_BYTE_OP_3: begin
        if (sdspi_busy == 0) begin
          r_data_w   = 1;
          next_state = END_OP;
        end
      end
      SET_SPEED_OP_0: begin
        next_state = STOP_OP_0;
      end
      STOP_OP_0: begin
        sdspi_r_multi_block_cl = 1;
        sdspi_rst = 1;
        next_state = STOP_OP_1;
      end
      STOP_OP_1: begin
        if (sdspi_busy == 0) begin
          next_state = END_OP;
        end
      end
      STOP_READ_OP_0: begin
        sdspi_r_multi_block_cl = 1;
        next_state = STOP_READ_OP_1;
      end
      STOP_READ_OP_1: begin
        if (sdspi_busy == 1) begin
          next_state = STOP_READ_OP_2;
        end
      end
      STOP_READ_OP_2: begin
        if (sdspi_busy == 0) begin
          next_state = END_OP;
        end
      end
      STOP_WRITE_OP_0: begin
        sdspi_w_byte = 1;
        if (sdspi_state == 8'h1A) begin
          next_state = STOP_WRITE_OP_1;
        end
      end
      STOP_WRITE_OP_1: begin
        if (sdspi_busy == 0) begin
          next_state = END_OP;
        end
      end
      END_OP: begin
        wb_ack_o = 1;
        if (wb_stb_i == 0) begin
          next_state = IDLE;
        end
      end
      default: begin
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
