#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_mux.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 13.03.2026
# Last Modified Date: 13.03.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>
import os
import random
import sys

import cocotb
import WishboneMaster
import numpy as np
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def setup(dut):
    clk_period = int((1*(10**9)) / int(dut.CLK_HZ.value))
    cocotb.start_soon(Clock(dut.wb_clk,clk_period,unit="ns").start())
    dut.wb_rst.value = 0




async def rst_test(dut, wb_master):
    wb_master.wb_rst_o.value = 1
    await n_cycles_clk(dut, 2)

    assert (
        int(dut.wb_display_impl.bridge_impl.current_state.value) == int(dut.wb_display_impl.bridge_impl.IDLE.value)
    ), f"ERROR IN RST, STATE IS {dut.wb_display_impl.bridge_impl.current_state.value}, EXPECTED {dut.wb_display_impl.bridge_impl.IDLE.value}"


    await n_cycles_clk(dut, 10)

    assert (
        int(dut.wb_display_impl.bridge_impl.current_state.value) == int(dut.wb_display_impl.bridge_impl.IDLE.value)
    ), f"ERROR IN RST, STATE IS {dut.wb_display_impl.bridge_impl.current_state.value}, EXPECTED {dut.wb_display_impl.bridge_impl.IDLE.value}"


    wb_master.wb_rst_o.value = 0


async def test_send_data(dut, data_test, wb_master):
    ADDR_DISPLAY_DATA = dut.wb_display_impl.bridge_impl.DISPLAY_DATA.value

    await wb_master.setup_write_operation(ADDR_DISPLAY_DATA, data_test)

    check_state(dut.wb_display_impl.bridge_impl, dut.wb_display_impl.bridge_impl.DISPLAY_DATA_OP_0.value)

    await n_cycles_clk(dut,1)

    dut._log.info(f"wb_dat is ={hex(dut.wb_impl.wb_dat.value)}")

    #comprobar que el dato esta en el display
    assert (dut.wb_display_impl.display_impl.din.value==data_test),f"ERROR SEND DATA, expected={hex(data_test)} calculated={hex(dut.wb_display_impl.display_impl.din.value)}"

    while(wb_master.wb_ack_i.value == 0):
        await n_cycles_clk(dut,1)


    check_state(dut.wb_display_impl.bridge_impl, dut.wb_display_impl.bridge_impl.END_OP.value)

    await wb_master.post_operation()

    check_state(dut.wb_display_impl.bridge_impl, dut.wb_display_impl.bridge_impl.IDLE.value)

    assert (dut.wb_display_impl.display_impl.din.value==data_test),f"ERROR POST-SEND DATA, expected={hex(data_test)} calculated={hex(dut.wb_display_impl.display_impl.din.value)}"


def check_state(dut,state):
    assert(int(dut.current_state.value)==int(state)),f"ERROR STATE, current_state={hex(dut.current_state.value)}, expected={hex(state)}"

async def n_cycles_clk(dut, n):
    for i in range(0, n):
        await RisingEdge(dut.wb_clk)
        await FallingEdge(dut.wb_clk)


@cocotb.test()
@cocotb.parametrize(index=range(0,10))
async def test(dut, index=0):
    random.seed(index)


    WB_DATA_WIDTH = int(dut.WB_DATA_WIDTH.value)
    data_test = random.getrandbits(WB_DATA_WIDTH)
    setup(dut)

    wb_master = WishboneMaster.WishboneMaster(dut)

    await rst_test(dut, wb_master)
    await test_send_data(dut,data_test,wb_master)



