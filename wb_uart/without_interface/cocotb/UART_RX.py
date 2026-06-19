#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : UART_RX.py
# Author            : German C.Quiveu <germancq@dte.us.es>
# Date              : 07.04.2026
# Last Modified Date: 07.04.2026
# Last Modified By  : German C.Quiveu <germancq@dte.us.es>

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import FallingEdge, RisingEdge, Timer

class UART_RX:
    def __init__(self,dut,clk=None):
        if clk==None:
            clk_period = int((1*(10**9)) / int(dut.CLK_HZ.value))
            cocotb.start_soon(Clock(dut.clk,clk_period,unit="ns").start())


    async def rst (self,rst,dut):
        rst.value = 1
        await self.n_cycles_clk(dut, 2)
        assert (
            int(dut.current_state.value) == int(dut.IDLE.value)
        ), f"ERROR IN RST, STATE IS {dut.current_state.value}, EXPECTED {dut.IDLE.value}"
        assert (
            dut.busy.value == 0
        ), f"ERROR IN RST BUSY value {
            dut.busy.value}"
        assert (
            dut.bits_counter_dout.value == 0
        ), f"ERROR IN RST BITS_COUNTER value {dut.bits_counter_dout.value}"
        assert (
            dut.sampling_counter_dout.value == 0
        ), f"ERROR IN RST SAMPLING_COUNTER value {dut.sampling_counter_dout.value}"

        await self.n_cycles_clk(dut, 10)
        assert (
            int(dut.current_state.value) == int(dut.IDLE.value)
        ), f"ERROR IN RST, STATE IS {dut.current_state.value}, EXPECTED {dut.IDLE.value}"

        rst.value = 0

    async def operation(self,rx,dut, test_byte):
        rx.value = 0
        await self.n_cycles_clk(dut, 1)


        assert (
            int(dut.current_state.value) == int(dut.START_BIT.value)
        ), f"ERROR IN TX, STATE IS {dut.current_state.value}, EXPECTED {dut.START_BIT.value}"


        assert (
            dut.busy.value == 1
        ), f"ERROR IN RST BUSY value {
            dut.busy.value}"

        dut._log.info(int(dut.CLK_HZ.value))
        dut._log.info(int(dut.BAUDIOS.value))
        dut._log.info(int(dut.CICLOS_PERIODO.value))

        while int(dut.sampling_counter_dout.value) != int(int(dut.CICLOS_PERIODO.value)/2) :
            assert (
                int(dut.current_state.value) == int(dut.START_BIT.value)
            ), f"ERROR IN RX, STATE IS {dut.current_state.value}, EXPECTED {dut.START_BIT.value}"
            await self.n_cycles_clk(dut, 1)

        assert(dut.sampling_rst.value == 1),f"ERROR SAMPLING RST"

        await self.n_cycles_clk(dut, 1)

        assert (
            dut.sampling_counter_dout.value == 0
        ), f"ERROR IN RST SAMPLING_COUNTER value {dut.sampling_counter_dout.value}"

        assert (
            int(dut.current_state.value) == int(dut.DATA_BITS.value)
        ), f"ERROR IN RX, STATE IS {dut.current_state.value}, EXPECTED {dut.DATA_BITS.value}"

        assert (
            dut.busy.value == 1
        ), f"ERROR IN RST BUSY value {
            dut.busy.value}"

        dut._log.info(hex(test_byte))
        for i in range(0, 8):
            bit_value = (test_byte >> i) & 0x1
            rx.value = bit_value

            assert (
                dut.bits_counter_dout.value == i
            ), f"ERROR IN RX, EXPECTED BITS_COUNTER = {hex(dut.bits_counter_dout.value)} CALCULATED = {hex(i)}"
            while int(dut.sampling_counter_dout.value) != int(dut.CICLOS_PERIODO.value):
                assert (
                    int(dut.current_state.value) == int(dut.DATA_BITS.value)
                ), f"ERROR IN RX, STATE IS {dut.current_state.value}, EXPECTED {dut.DATA_BITS.value}"
                await self.n_cycles_clk(dut, 1)
            await self.n_cycles_clk(dut, 1)

        assert (
            int(dut.current_state.value) == int(dut.STOP_BIT.value)
        ), f"ERROR IN TX, STATE IS {dut.current_state.value}, EXPECTED {dut.STOP_BIT.value}"

        while int(dut.sampling_counter_dout.value) != int(dut.CICLOS_PERIODO.value):
            assert (
                int(dut.current_state.value) == int(dut.STOP_BIT.value)
            ), f"ERROR IN RX, STATE IS {dut.current_state.value}, EXPECTED {dut.STOP_BIT.value}"
            await self.n_cycles_clk(dut, 1)

        await self.n_cycles_clk(dut,1)

        assert (int(dut.dout.value) == test_byte),f"ERROR IN DOUT, expected = {hex(test_byte)} calculated = {hex(dut.dout.value)}"

        assert (
            int(dut.current_state.value) == int(dut.DONE.value)
        ), f"ERROR IN RX, STATE IS {dut.current_state.value}, EXPECTED {dut.DONE.value}"

        assert (
            dut.busy.value == 0
        ), f"ERROR IN RX ACTIVE value {
            dut.busy.value}"

        assert (
            dut.done.value == 1
        ), f"ERROR IN RX DONE value {
            dut.done.value}"

    async def n_cycles_clk(self,dut, n):
        for i in range(0, n):
            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)

