/**
 * File              : wb_ascon.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 19.10.2026
 * Last Modified Date: 19.10.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_ascon #(
    parameter KEY_LEN = 128,
    parameter BLK_LEN = 128,
    parameter WB_DATA_WIDTH = 32,
    parameter WB_ADDR_DIR = 16,
    parameter OFFSET_ADDR = 1,
    parameter version = 1,
    parameter a = 12,
    parameter b = 8,
    parameter rate = 16
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


  logic ascon_rst;
  logic [KEY_LEN-1:0] ascon_key;
  logic [127:0] ascon_nonce;
  logic ascon_start;
  logic ascon_enc_dec;
  logic [BLK_LEN-1:0] ascon_blk_i;
  logic [BLK_LEN-1:0] ascon_blk_o;
  logic [127:0] ascon_tag;
  logic ascon_feed_block;
  logic ascon_feed_complete;
  logic ascon_last_block;
  logic ascon_end_signal;
  ascon_wb_bridge #(
      .KEY_LEN(KEY_LEN),
      .BLK_LEN(BLK_LEN),
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
      .ascon_rst(ascon_rst),
      .ascon_key(ascon_key),
      .ascon_nonce(ascon_nonce),
      .ascon_start(ascon_start),
      .ascon_enc_dec(ascon_enc_dec),
      .ascon_blk_i(ascon_blk_i),
      .ascon_blk_o(ascon_blk_o),
      .ascon_tag(ascon_tag),
      .ascon_feed_block(ascon_feed_block),
      .ascon_feed_complete(ascon_feed_complete),
      .ascon_last_block(ascon_last_block),
      .ascon_end_signal(ascon_end_signal)
  );


  ascon #(
      .a(a),
      .b(b),
      .k(KEY_LEN),
      .rate(rate),
      .version(version)
  ) ascon_inst (
      .clk(wb_clk),
      .rst(wb_rst || ascon_rst),
      .start(ascon_start),
      .enc_dec(ascon_enc_dec),
      .key(ascon_key),
      .nonce(ascon_nonce),
      .block_i(ascon_blk_i),
      .feed_block(ascon_feed_block),
      .feed_complete(ascon_feed_complete),
      .last_block(ascon_last_block),
      .block_o(ascon_blk_o),
      .tag(ascon_tag),
      .end_signal(ascon_end_signal)
  );

endmodule
