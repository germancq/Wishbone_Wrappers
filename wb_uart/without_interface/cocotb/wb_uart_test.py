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
import UART
import numpy as np
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def setup(dut):
    clk_period = int((1*(10**9)) / int(dut.CLK_HZ.value))
    cocotb.start_soon(Clock(dut.wb_clk,clk_period,unit="ns").start())
    dut.wb_rst.value = 0

    dut.rx.value = 1



async def rst_test(dut, wb_master):
    wb_master.wb_rst_o.value = 1
    await n_cycles_clk(dut, 2)

    assert (
        int(dut.bridge_impl.current_state.value) == int(dut.bridge_impl.IDLE.value)
    ), f"ERROR IN RST, STATE IS {dut.bridge_impl.current_state.value}, EXPECTED {dut.bridge_impl.IDLE.value}"


    await n_cycles_clk(dut, 10)

    assert (
        int(dut.bridge_impl.current_state.value) == int(dut.bridge_impl.IDLE.value)
    ), f"ERROR IN RST, STATE IS {dut.bridge_impl.current_state.value}, EXPECTED {dut.bridge_impl.IDLE.value}"


    wb_master.wb_rst_o.value = 0


async def test_send_data(dut, data_test, wb_master):
    ADDR_SEND_DATA = dut.bridge_impl.UART_SEND_DATA.value

    await wb_master.setup_write_operation(ADDR_SEND_DATA, data_test)

    assert(int(dut.bridge_impl.current_state.value)==int(dut.bridge_impl.SEND_BYTE_OP_0.value)),f"ERROR SEND DATA STATE, current_state = {hex(dut.bridge_impl.current_state.value)} expected={hex(dut.bridge_impl.SEND_BYTE_OP_0.value)}"

    await n_cycles_clk(dut,1)

    #comprobar que esta activa la uart
    assert (dut.uart_impl.tx_active.value==1),f"ERROR SEND DATA, UART NOT ACTIVE"

    while(wb_master.wb_ack_i.value == 0):
        await n_cycles_clk(dut,1)


    assert(int(dut.bridge_impl.current_state.value)==int(dut.bridge_impl.END_OP.value)),f"ERROR SEND DATA END_OP STATE, current_state = {hex(dut.bridge_impl.current_state.value)} expected={hex(dut.bridge_impl.END_OP.value)}"

    await wb_master.post_operation()

    assert(int(dut.bridge_impl.current_state.value)==int(dut.bridge_impl.IDLE.value)),f"ERROR SEND DATA IDLE STATE, current_state = {hex(dut.bridge_impl.current_state.value)} expected={hex(dut.bridge_impl.IDLE.value)}"


async def test_recv_data(dut, data_test, wb_master, uart):
    ADDR_RECV_DATA = dut.bridge_impl.UART_RCV_DATA.value

    await wb_master.setup_read_operation(ADDR_RECV_DATA)

    check_state(dut.bridge_impl, dut.bridge_impl.RECV_BYTE_OP_0.value)

    await uart.read(dut.rx,dut.uart_impl,data_test)

    await n_cycles_clk(dut,1)

    check_state(dut.bridge_impl, dut.bridge_impl.END_OP.value)
    
    dut._log.info(hex(dut.bridge_impl.wb_data.value))

    assert(int(dut.wb_dat_o.value)==data_test),f"ERROR WB_READ, DAT_O_EXPECTED={hex(data_test)} calculated={hex(dut.wb_dat_o.value)}"


async def test_ctrl_data(dut, wb_master, rx_value):
    ADDR_CTRL_DATA = dut.bridge_impl.UART_CTRL_DATA.value

    dut.rx.value = rx_value

    await wb_master.setup_read_operation(ADDR_CTRL_DATA)

    check_state(dut.bridge_impl, dut.bridge_impl.CTRL_DATA_OP_0.value)

    await n_cycles_clk(dut,1)

    check_state(dut.bridge_impl, dut.bridge_impl.END_OP.value)

    assert(int(dut.wb_dat_o.value) == ((1^rx_value)&0x1)),f"ERROR RX_ACTIVE IN CTRL DATA"


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


    data_test = random.getrandbits(8)
    setup(dut)

    wb_master = WishboneMaster.WishboneMaster(dut)
    uart_dut = UART.UART(dut.uart_impl,clk=dut.wb_clk)

    await rst_test(dut, wb_master)
    await test_send_data(dut,data_test,wb_master)
    await test_recv_data(dut,data_test,wb_master, uart_dut)

    await rst_test(dut, wb_master)
    await test_ctrl_data(dut,wb_master,1)

    await rst_test(dut, wb_master)
    await test_ctrl_data(dut,wb_master,0)


