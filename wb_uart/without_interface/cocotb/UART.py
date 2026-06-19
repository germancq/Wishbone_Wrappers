#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : UART.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 07.04.2026
# Last Modified Date: 07.04.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

import cocotb
import UART_RX
import UART_TX
import numpy as np
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer

class UART:
    def __init__(self,dut,clk=None):
        if clk==None:
            clk_period = int((1*(10**9)) / int(dut.CLK_HZ.value))
            cocotb.start_soon(Clock(dut.clk,clk_period,unit="ns").start())

        self.uart_tx = UART_TX.UART_TX(dut.transmision,clk)
        self.uart_rx = UART_RX.UART_RX(dut.recepcion,clk)

    async def rst (self,rst,dut):
        rst.value = 1

        await self.n_cycles_clk(dut, 2)

        assert (
            int(dut.recepcion.current_state.value) == int(dut.recepcion.IDLE.value)
        ), f"ERROR IN RST UART_RX, STATE IS {dut.recepcion.current_state.value}, EXPECTED {dut.recepcion.IDLE.value}"

        assert (
            int(dut.transmision.current_state.value) == int(dut.transmision.IDLE.value)
        ), f"ERROR IN RST UART_TX, STATE IS {dut.transmision.current_state.value}, EXPECTED {dut.transmision.IDLE.value}"

        await self.n_cycles_clk(dut, 10)
        assert (
            int(dut.recepcion.current_state.value) == int(dut.recepcion.IDLE.value)
        ), f"ERROR IN RST UART_RX, STATE IS {dut.recepcion.current_state.value}, EXPECTED {dut.recepcion.IDLE.value}"

        assert (
            int(dut.transmision.current_state.value) == int(dut.transmision.IDLE.value)
        ), f"ERROR IN RST UART_TX, STATE IS {dut.transmision.current_state.value}, EXPECTED {dut.transmision.IDLE.value}"

        rst.value = 0

    async def read(self,rx,dut, test_byte):
        await self.uart_rx.operation(rx,dut.recepcion,test_byte)
        assert(int(dut.rx_done.value) == 1),f"ERROR read, RX_DONE"
        assert(int(dut.rx_byte.value) == test_byte),f"ERROR read data, expected = {hex(test_byte)} calculated={hex(dut.rx_byte_value)} "

    async def write(self, start,din,dut, test_byte):
        await self.uart_tx.operation(start,din,dut.transmision,test_byte)
        assert(int(dut.tx_done.value) == 1),f"ERROR write, TX_DONE"


    async def n_cycles_clk(self,dut, n):
        for i in range(0, n):
            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

