/**
 * File              : wb_mem.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 18.02.2026
 * Last Modified Date: 26.11.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module wb_mem #(
    parameter WB_DATA_WIDTH = 32,
    parameter WIDTH_MEM = 32,
    parameter ADDR_MEM = 1024,
    parameter FILE_MEM = "memory.mem"
) (
    input                                 wb_clk,
    input                                 wb_rst,
    //wishbone interface
    input        [  $clog2(ADDR_MEM)-1:0] wb_adr_i,
    input        [     WB_DATA_WIDTH-1:0] wb_dat_i,
    input                                 wb_we_i,
    input                                 wb_cyc_i,
    input                                 wb_stb_i,
    input        [(WB_DATA_WIDTH>>3)-1:0] wb_sel_i,
    input        [                   2:0] wb_cti_i,
    input        [                   1:0] wb_bte_i,
    output logic                          wb_ack_o,
    output logic                          wb_err_o,
    output                                wb_rty_o,
    output       [     WB_DATA_WIDTH-1:0] wb_dat_o
);

  mod_memory_module #(
      .DATA_WIDTH(WIDTH_MEM),
      .ADDR($clog2(ADDR_MEM)),
      .FILE_MEM(FILE_MEM)
  ) mem_inst (
      .clk(wb_clk),
      .we(wb_we_i & wb_stb_i & wb_cyc_i),
      .sel(wb_sel_i),
      .addr(wb_adr_i[$clog2(ADDR_MEM)-1:2]),
      .din(wb_dat_i),
      .dout(wb_dat_o),
      .reset_values(wb_rst)
  );




  localparam IDLE = 0;
  localparam END_OP = 1;

  logic [0:0] current_state, next_state;

  always_comb begin
    next_state = current_state;
    wb_err_o   = 0;
    wb_ack_o   = 0;

    case (current_state)
      IDLE: begin
        if (wb_stb_i & wb_cyc_i) begin
          next_state = END_OP;
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
