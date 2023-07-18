#pragma once

#include "CpuRefImpl.h"
#include "tools.h"

#include <array>
#include <cstdint>
#include <iomanip>
#include <iostream>


constexpr const uint32_t UART_DATA_ADDR = 0xbfd003f8;
constexpr const uint32_t UART_CTL_ADDR  = 0xbfd003fC;

// 指令PC及提交后状态
struct Status {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};


inline bool compare_status(const Status &pracImpl, const Status &refImpl) {
    std::stringstream pracStr, refStr;

    bool pc_equ  = (pracImpl.pc == refImpl.pc);
    bool gpr_equ = true;
    for (size_t i = 0; i < 32; ++i) {
        if (pracImpl.gpr[i] != refImpl.gpr[i]) {
            gpr_equ = false;
            break;
        }
    }
    if (pc_equ && gpr_equ)
        return true;

    if (!pc_equ) {
        pracStr << CTL_RED << "[PC] 0x" << std::hex << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_GREEN << "[PC] 0x" << std::hex << refImpl.pc << CTL_RESET << '\n';
    } else {
        pracStr << CTL_RESET << "[PC] 0x" << std::hex << pracImpl.pc << CTL_RESET << '\n';
        refStr << CTL_RESET << "[PC] 0x" << std::hex << refImpl.pc << CTL_RESET << '\n';
    }
    for (size_t i = 0; i < 8; ++i) {
        for (size_t j = 0; j < 4; ++j) {
            auto ind = i * 4 + j;
            if (pracImpl.gpr[ind] != refImpl.gpr[ind]) {
                pracStr << CTL_RED << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << pracImpl.gpr[ind] << CTL_RESET << "   ";
                refStr << CTL_GREEN << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << refImpl.gpr[ind] << CTL_RESET << "   ";
            } else {
                pracStr << CTL_RESET << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << pracImpl.gpr[ind] << CTL_RESET << "   ";
                refStr << CTL_RESET << std::dec << "GPR[" << std::setw(2) << ind << "]: 0x" << std::hex << std::setw(8) << std::setfill('0') << refImpl.gpr[ind] << CTL_RESET << "   ";
            }
        }
        pracStr << '\n';
        refStr << '\n';
    }
    std::cout << CTL_ORIANGE << "RefImpl  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RefImpl" CTL_RESET "\n";
    std::cout << refStr.str();
    std::cout << CTL_ORIANGE << "=================================================" CTL_RESET "\n";
    std::cout << pracStr.str();
    std::cout << CTL_ORIANGE << "PracImpl <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PracImpl" CTL_RESET "\n";

    return false;
}

template <typename T>
void uart_putc(T &cpu, difftest::CpuRefImpl &cpuRef, char ch) {
    print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Go into UART send -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Wait to send %c(0x%08X)", ch, ch);
    // Start bit
    cpu->rxd_i = 0;
    cpu.step();
    // Data bit
    for (int i = 0; i < 8 && !cpu.lastStatus.uartRxReady; ++i) {
        cpu->rxd_i = (ch >> i) & 0x01;
        cpu.step();
        bool waitingUartRx = !cpu.lastStatus.uartRxReady && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "PracPc: 0x%08X", cpu.lastStatus.pc);
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "send 0x%01X in %c at [%d]", (ch >> i) & 0x01, ch, i);
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "ready: %d", cpu.lastStatus.uartRxReady);
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "rxd_i: 0x%01X", cpu->rxd_i);
    }
    // End bit
    cpu->rxd_i = 1;
    cpu.step();

    // CPU 完成 load，并执行完当前指令
    while (cpu.nowStatus.targetAddr != UART_CTL_ADDR || (cpu.nowStatus.targetData & 0x02) != 0x02 || cpu.lastStatus.pc == cpu.nowStatus.pc) {
        cpu.step();
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Complete Receiving -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    }
    cpu.step();
    // while (cpuRef.get_gpr())

    // 同步至 CpuRef
    // 当
    // bool waitingUartRx = !cpu.lastStatus.uartRxReady || ((cpu.nowStatus.targetAddr == UART_CTL_ADDR) && ((cpu.nowStatus.targetData & 0x02) != 0x02));
    // debug("a: %d, b: %d", cpu.lastStatus.uartRxReady, (cpu.nowStatus.targetAddr == UART_CTL_ADDR));

    while (cpu.lastStatus.pc != cpuRef.get_pc()) {
        cpuRef.step();
        print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Sync -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    }
    return;
}