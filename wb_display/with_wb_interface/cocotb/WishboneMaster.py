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
        self.wb_clk = dut.wb_impl.wb_clk
        self.wb_rst_o = dut.wb_impl.wb_rst
        self.wb_ack_i = dut.wb_impl.wb_ack
        self.wb_err_i = dut.wb_impl.wb_err
        self.wb_dat_i = dut.wb_impl.wb_rdt
        self.wb_rty_i = dut.wb_impl.wb_rty
        self.wb_dat_o = dut.wb_impl.wb_dat
        self.wb_cyc_o = dut.wb_impl.wb_cyc
        self.wb_stb_o = dut.wb_impl.wb_stb
        self.wb_sel_o = dut.wb_impl.wb_sel
        self.wb_we_o = dut.wb_impl.wb_we
        self.wb_cti_o = dut.wb_impl.wb_cti
        self.wb_bte_o = dut.wb_impl.wb_bte
        self.wb_adr_o = dut.wb_impl.wb_adr

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


