/**
 * File              : ascon_wb_bridge.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 11.04.2025
 * Last Modified Date: 08.10.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */
//KEY, NONCE, BLOCK_I, BLOCK_O is always 128 bits blocks
module ascon_wb_bridge #(
    parameter KEY_LEN = 128,
    parameter BLK_LEN = 128,
    parameter WB_ADDR_DIR = 32,
    parameter WB_DATA_WIDTH = 32,
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
    //block_cipher interface
    output logic                           ascon_rst,
    output       [                  127:0] ascon_key,
    output       [                  127:0] ascon_nonce,
    output                                 ascon_start,
    output logic                           ascon_enc_dec,
    output       [                  127:0] ascon_blk_i,
    input        [                  127:0] ascon_blk_o,
    output       [                  127:0] ascon_tag,
    output                                 ascon_feed_block,
    input                                  ascon_feed_complete,
    output                                 ascon_last_block,
    input                                  ascon_end_signal
);

  localparam SET_KEY_0 = 0 * OFFSET_ADDR;
  localparam SET_KEY_1 = 1 * OFFSET_ADDR;
  localparam SET_KEY_2 = 2 * OFFSET_ADDR;
  localparam SET_KEY_3 = 3 * OFFSET_ADDR;

  localparam SET_NONCE_0 = 4 * OFFSET_ADDR;
  localparam SET_NONCE_1 = 5 * OFFSET_ADDR;
  localparam SET_NONCE_2 = 6 * OFFSET_ADDR;
  localparam SET_NONCE_3 = 7 * OFFSET_ADDR;

  localparam SET_BLOCK_I_0 = 8 * OFFSET_ADDR;
  localparam SET_BLOCK_I_1 = 9 * OFFSET_ADDR;
  localparam SET_BLOCK_I_2 = 10 * OFFSET_ADDR;
  localparam SET_BLOCK_I_3 = 11 * OFFSET_ADDR;


  localparam GET_BLOCK_O_0 = 12 * OFFSET_ADDR;
  localparam GET_BLOCK_O_1 = 13 * OFFSET_ADDR;
  localparam GET_BLOCK_O_2 = 14 * OFFSET_ADDR;
  localparam GET_BLOCK_O_3 = 15 * OFFSET_ADDR;

  localparam GET_TAG_0 = 16 * OFFSET_ADDR;
  localparam GET_TAG_1 = 17 * OFFSET_ADDR;
  localparam GET_TAG_2 = 18 * OFFSET_ADDR;
  localparam GET_TAG_3 = 19 * OFFSET_ADDR;

  localparam RST_CIPHER = 20 * OFFSET_ADDR;

  localparam SET_ENC_DEC = 21 * OFFSET_ADDR;

  //param last_block
  localparam FEED_CIPHER = 22 * OFFSET_ADDR;
  genvar i;


  assign wb_rty_o = 1;

  logic [WB_DATA_WIDTH-1:0] bank_register[31:0];
  generate
    for (i = 0; i < 32; i = i + 1) begin
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


  generate
    for (i = 0; i < (KEY_LEN / WB_DATA_WIDTH); i = i + 1) begin
      assign ascon_key[(WB_DATA_WIDTH)+(i*WB_DATA_WIDTH)-1:(i*WB_DATA_WIDTH)] = bank_register[i];
    end
  endgenerate

  generate
    for (i = 0; i < (KEY_LEN / WB_DATA_WIDTH); i = i + 1) begin
      assign ascon_nonce[(WB_DATA_WIDTH)+(i*WB_DATA_WIDTH)-1:(i*WB_DATA_WIDTH)] = bank_register[4+i];
    end
  endgenerate

  generate
    for (i = 0; i < (BLK_LEN / WB_DATA_WIDTH); i = i + 1) begin
      assign ascon_blk_i[(WB_DATA_WIDTH)+(i*WB_DATA_WIDTH)-1:(i*WB_DATA_WIDTH)] = bank_register[8+i];
    end
  endgenerate

  assign ascon_enc_dec = bank_register[21];
  assign ascon_last_block = bank_register[22];

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

  logic [3:0] current_state, next_state;

  localparam START_STATE = 0;
  localparam IDLE = 1;
  localparam END_OP = 2;
  localparam RST_OP_0 = 3;
  localparam START_OP_0 = 4;
  localparam GET_BLOCK_OP = 5;

  always_comb begin
    next_state = current_state;
    wb_err_o = 0;
    wb_ack_o = 0;

    r_data_w = 0;
    wb_data = ascon_blk_o;

    ascon_rst = 0;
    ascon_feed_block = 0;
    ascon_start = 0;

    case (current_state)
      START_STATE: begin
        ascon_rst  = 1;
        next_state = IDLE;
      end
      IDLE: begin
        if (wb_stb_i) begin
          case (wb_adr_i)
            RST_CIPHER: next_state = RST_OP_0;
            FEED_CIPHER: next_state = START_OP_0;
            GET_BLOCK_O_0: next_state = GET_BLOCK_OP;
            GET_BLOCK_O_1: next_state = GET_BLOCK_OP;
            GET_BLOCK_O_2: next_state = GET_BLOCK_OP;
            GET_BLOCK_O_3: next_state = GET_BLOCK_OP;
            GET_TAG_0: next_state = GET_BLOCK_OP;
            GET_TAG_1: next_state = GET_BLOCK_OP;
            GET_TAG_2: next_state = GET_BLOCK_OP;
            GET_TAG_3: next_state = GET_BLOCK_OP;
            default: next_state = END_OP;
          endcase
        end
      end
      RST_OP_0: begin
        ascon_rst  = 1;
        next_state = END_OP;
      end
      START_OP_0: begin
        ascon_feed_block = 1;
        ascon_start = 1;
        if (ascon_feed_complete == 1) begin
          next_state = END_OP;
        end
      end
      GET_BLOCK_OP: begin
        case (wb_adr_i)
          GET_BLOCK_O_0: begin
            wb_data = ascon_blk_o[WB_DATA_WIDTH-1:0];
          end
          GET_BLOCK_O_1: begin
            if (BLK_LEN > WB_DATA_WIDTH) begin
              wb_data = ascon_blk_o[(2*WB_DATA_WIDTH)-1:WB_DATA_WIDTH];
            end else begin
              wb_data = ascon_blk_o[WB_DATA_WIDTH-1:0];
            end
          end
          GET_BLOCK_O_2: begin
            if (BLK_LEN > 2 * WB_DATA_WIDTH) begin
              wb_data = ascon_blk_o[(3*WB_DATA_WIDTH)-1:(2*WB_DATA_WIDTH)];
            end else begin
              wb_data = ascon_blk_o[WB_DATA_WIDTH-1:0];
            end

          end
          GET_BLOCK_O_3: begin
            if (BLK_LEN > 3 * WB_DATA_WIDTH) begin
              wb_data = ascon_blk_o[(4*WB_DATA_WIDTH)-1:(3*WB_DATA_WIDTH)];
            end else begin
              wb_data = ascon_blk_o[WB_DATA_WIDTH-1:0];
            end

          end
          GET_TAG_0: begin
            wb_data = ascon_tag[WB_DATA_WIDTH-1:0];
          end
          GET_TAG_1: begin
            if (BLK_LEN > WB_DATA_WIDTH) begin
              wb_data = ascon_tag[(2*WB_DATA_WIDTH)-1:WB_DATA_WIDTH];
            end else begin
              wb_data = ascon_tag[WB_DATA_WIDTH-1:0];
            end
          end
          GET_TAG_2: begin
            if (BLK_LEN > 2 * WB_DATA_WIDTH) begin
              wb_data = ascon_tag[(3*WB_DATA_WIDTH)-1:(2*WB_DATA_WIDTH)];
            end else begin
              wb_data = ascon_tag[WB_DATA_WIDTH-1:0];
            end

          end
          GET_TAG_3: begin
            if (BLK_LEN > 3 * WB_DATA_WIDTH) begin
              wb_data = ascon_tag[(4*WB_DATA_WIDTH)-1:(3*WB_DATA_WIDTH)];
            end else begin
              wb_data = ascon_tag[WB_DATA_WIDTH-1:0];
            end

          end

          default: wb_data = ascon_blk_o[WB_DATA_WIDTH-1:0];
        endcase
        r_data_w   = 1;
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
