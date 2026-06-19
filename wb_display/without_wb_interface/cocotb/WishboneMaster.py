#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : WishboneMaster.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 06.04.2026
# Last Modified Date: 06.04.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer

class WishboneMaster:
    def __init__ (self, dut):
        self.wb_clk = dut.wb_clk
        self.wb_rst_o = dut.wb_rst
        self.wb_ack_i = dut.wb_ack_o
        self.wb_err_i = dut.wb_err_o
        self.wb_dat_i = dut.wb_dat_o
        self.wb_rty_i = dut.wb_rty_o
        self.wb_dat_o = dut.wb_dat_i
        self.wb_cyc_o = dut.wb_cyc_i
        self.wb_stb_o = dut.wb_stb_i
        self.wb_sel_o = dut.wb_sel_i
        self.wb_we_o = dut.wb_we_i
        self.wb_cti_o = dut.wb_cti_i
        self.wb_bte_o = dut.wb_bte_i
        self.wb_adr_o = dut.wb_adr_i

        self.wb_cyc_o.value = 0
        self.wb_stb_o.value = 0

    async def wait_cycles(self,n):
        for _ in range(n):
            await RisingEdge(self.wb_clk)
            await FallingEdge(self.wb_clk)

    async def setup_write_operation(self, address, data):
        self.wb_adr_o.value = int(address)
        self.wb_dat_o.value = int(data)
        self.wb_stb_o.value = 1
        self.wb_cyc_o.value = 1
        self.wb_we_o.value = 1

        await self.wait_cycles(1)

        

    async def post_operation(self):
        self.wb_stb_o.value = 0
        self.wb_cyc_o.value = 0
        self.wb_we_o.value = 0
        await self.wait_cycles(1)


    async def setup_read_operation(self,address):
        self.wb_adr_o.value = int(address)
        self.wb_stb_o.value = 1
        self.wb_cyc_o.value = 1
        self.wb_we_o.value = 0
        await self.wait_cycles(1)


