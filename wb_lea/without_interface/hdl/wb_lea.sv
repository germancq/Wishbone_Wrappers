/**
 * File              : LEA_wb.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 15.04.2026
 * Last Modified Date: 15.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_lea #(
    parameter WB_DATA_WIDTH = 32,
    parameter WB_ADDR_DIR = 16,
    parameter OFFSET_ADDR = 1,
    parameter KEY_LEN = 128,
    parameter BLK_LEN = 128
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

  logic cipher_rst, cipher_end_signal, cipher_rq_data, cipher_enc_dec, cipher_end_key_generation;
  logic [KEY_LEN-1:0] cipher_key;
  logic [BLK_LEN-1:0] cipher_blk_o, cipher_blk_i;

  block_cipher_wb_bridge #(
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
      .cipher_rst(cipher_rst),
      .cipher_key(cipher_key),
      .cipher_end_key_generation(cipher_end_key_generation),
      .cipher_blk_i(cipher_blk_i),
      .cipher_blk_o(cipher_blk_o),
      .cipher_enc_dec(cipher_enc_dec),
      .cipher_rq_data(cipher_rq_data),
      .cipher_end_signal(cipher_end_signal)
  );

  LEA #(
      .KEY_LEN(KEY_LEN)
  ) LEA_impl (
      .clk(wb_clk),
      .rst(cipher_rst),
      .end_key_generation(cipher_end_key_generation),
      .key(cipher_key),
      .block_i(cipher_blk_i),
      .block_o(cipher_blk_o),
      .rq_data(cipher_rq_data),
      .end_signal(cipher_end_signal)
  );
endmodule

