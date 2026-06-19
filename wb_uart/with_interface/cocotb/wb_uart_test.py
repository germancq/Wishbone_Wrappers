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

async def rst_test(dut, wb_master):
    dut.wb_rst.value = 1
    await n_cycles_clk(dut, 2)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.IDLE.value)

    await n_cycles_clk(dut, 10)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.IDLE.value)


    dut.wb_rst.value = 0


async def test_send_data(dut, data_test, wb_master):
    ADDR_SEND_DATA = dut.wb_uart_impl.bridge_impl.UART_SEND_DATA.value

    await wb_master.setup_write_operation(ADDR_SEND_DATA, data_test)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.SEND_BYTE_OP_0.value)

    await n_cycles_clk(dut,1)

    #comprobar que esta activa la uart
    assert (dut.wb_uart_impl.uart_impl.tx_active.value==1),f"ERROR SEND DATA, UART NOT ACTIVE"

    while(wb_master.wb_ack_i.value == 0):
        await n_cycles_clk(dut,1)


    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.END_OP.value)

    await wb_master.post_operation()

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.IDLE.value)


async def test_recv_data(dut, data_test, wb_master, uart):
    ADDR_RECV_DATA = dut.wb_uart_impl.bridge_impl.UART_RCV_DATA.value

    await wb_master.setup_read_operation(ADDR_RECV_DATA)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.RECV_BYTE_OP_0.value)

    await uart.read(dut.rx,dut.wb_uart_impl.uart_impl,data_test)

    await n_cycles_clk(dut,1)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.END_OP.value)
    
    dut._log.info(hex(dut.wb_uart_impl.bridge_impl.wb_data.value))

    assert(int(dut.wb_impl.wb_rdt.value)==data_test),f"ERROR WB_READ, DAT_O_EXPECTED={hex(data_test)} calculated={hex(dut.wb_dat_o.value)}"


async def test_ctrl_data(dut, wb_master, rx_value):
    ADDR_CTRL_DATA = dut.wb_uart_impl.bridge_impl.UART_CTRL_DATA.value

    dut.rx.value = rx_value

    await wb_master.setup_read_operation(ADDR_CTRL_DATA)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.CTRL_DATA_OP_0.value)

    await n_cycles_clk(dut,1)

    check_state(dut.wb_uart_impl.bridge_impl, dut.wb_uart_impl.bridge_impl.END_OP.value)

    assert(int(dut.wb_impl.wb_rdt.value) == ((1^rx_value)&0x1)),f"ERROR RX_ACTIVE IN CTRL DATA"


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

    wb_master = WishboneMaster.WishboneMaster(dut.wb_impl)
    uart_dut = UART.UART(dut.wb_uart_impl.uart_impl,clk=dut.wb_clk)

    await rst_test(dut, wb_master)
    await test_send_data(dut,data_test,wb_master)
    await test_recv_data(dut,data_test,wb_master, uart_dut)

    await rst_test(dut, wb_master)
    await test_ctrl_data(dut,wb_master,1)

    await rst_test(dut, wb_master)
    await test_ctrl_data(dut,wb_master,0)


