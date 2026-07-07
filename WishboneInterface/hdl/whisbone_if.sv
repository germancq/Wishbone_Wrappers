/**
 * File              : whisbone_if.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 08.04.2026
 * Last Modified Date: 08.04.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

interface whisbone_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input wb_clk,
    input wb_rst
);


  logic [DATA_WIDTH-1:0] wb_dat;
  logic [DATA_WIDTH-1:0] wb_rdt;
  logic [ADDR_WIDTH-1:0] wb_adr;
  logic [(DATA_WIDTH>>3)-1:0] wb_sel;
  logic [2:0] wb_cti;
  logic [1:0] wb_bte;
  logic wb_cyc;
  logic wb_ack;
  logic wb_we;
  logic wb_rty;
  logic wb_stb;
  logic wb_err;

  modport master(
      input wb_ack,
      input wb_rdt,
      input wb_clk,
      input wb_rst,
      input wb_rty,
      input wb_err,
      output wb_cti,
      output wb_bte,
      output wb_stb,
      output wb_dat,
      output wb_adr,
      output wb_sel,
      output wb_cyc,
      output wb_we
  );

  modport slave(
      input wb_dat,
      input wb_adr,
      input wb_cyc,
      input wb_we,
      input wb_sel,
      input wb_clk,
      input wb_rst,
      input wb_stb,
      input wb_bte,
      input wb_cti,
      output wb_rdt,
      output wb_rty,
      output wb_ack,
      output wb_err
  );

  modport slaveconn(
      input wb_ack, wb_rdt, wb_clk, wb_rst,
      output wb_dat, wb_adr, wb_sel, wb_cyc, wb_stb, wb_we
  );

  modport masterconn(
      input wb_dat, wb_adr, wb_cyc, wb_stb, wb_we, wb_sel, wb_clk, wb_rst,
      output wb_rdt, wb_ack
  );

endinterface
