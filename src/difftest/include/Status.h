#pragma once

#include "CpuRefImpl.h"
#include <core/la32r/la32r_core.hpp>
#include <core/la32r/la32r_common.hpp>
#include "tools.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <thread>


constexpr const uint32_t UART_DATA_ADDR = 0xbfd003f8;
constexpr const uint32_t UART_CTL_ADDR  = 0xbfd003fC;

// 指令PC及提交后状态
struct Status {
    uint32_t                 pc;
    std::array<uint32_t, 32> gpr;
};

template <typename T>
inline bool compare_status(const Status &pracImpl, const Status &refImpl, T &cpu) {
    std::stringstream pracStr, refStr;

    bool pc_equ  = (pracImpl.pc == refImpl.pc);
    bool gpr_equ = true;
    for (size_t i = 0; i < 32; ++i) {
        if (pracImpl.gpr[i] != refImpl.gpr[i]) {
            gpr_equ = false;
            break;
        }
    }
    if (pc_equ && (gpr_equ || cpu.lastStatus.targetAddr == UART_CTL_ADDR))
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
    auto cpu_step5208 = [&]() {for (int _ = 0; _ < 1; ++_) cpu.step(); };
    // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Go into UART send -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Wait to send %c(0x%08X)", ch, ch);
    // Start bit
    cpu->rxd_i        = 0;
    cpu_step5208();
    // Data bit
    for (int i = 0; i < 8 && !cpu.lastStatus.uartRxReady; ++i) {
        cpu->rxd_i = (ch >> i) & 0x01;
        cpu_step5208();
        bool waitingUartRx = !cpu.lastStatus.uartRxReady && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "PracPc: 0x%08X", cpu.lastStatus.pc);
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "send 0x%01X in %c at [%d]", (ch >> i) & 0x01, ch, i);
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "ready: %d", cpu.lastStatus.uartRxReady);
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "rxd_i: 0x%01X", cpu->rxd_i);
    }
    // End bit
    cpu->rxd_i = 1;
    cpu_step5208();

    // CPU 完成 load，并执行完当前指令
    while (cpu.nowStatus.targetAddr != UART_CTL_ADDR || (cpu.nowStatus.targetData & 0x02) != 0x02 || cpu.lastStatus.pc == cpu.nowStatus.pc) {
        cpu.step();
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Complete Receiving -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    }
    cpu.step();

    // 同步至 CpuRef
    while (cpu.lastStatus.pc != cpuRef.get_pc()) {
        cpuRef.step();
        // print_d(CTL_LIGHTBLUE, "[UART.RX] " CTL_RESET "Sync -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
    }
    return;
}


template <typename T>
void print_ext(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_ORIANGE, "===============================================================================" CTL_RESET);
    print_info("ExtRAM 0x0 ~ 0x100");
    uint8_t buff[512];
    cpuRef.mmio.do_read(0x80400000, 0x100, buff);
    for (int i = 0; i < 16; ++i) {
        std::printf("%08x: ", i * 16);
        for (int j = 0; j < 16; ++j) {
            std::printf("%02x ", buff[i * 16 + j]);
        }
        std::printf("\n");
    }

    print_d(CTL_ORIANGE, "===============================================================================" CTL_RESET);
    print_info("ExtRAM 0x100 ~ 0x10c ");
    cpuRef.mmio.do_read(0x80400100, 0xc, buff);
    for (int j = 0; j < 0xc; ++j) {
        std::printf("%02x ", buff[j]);
    }
    std::printf("\n");

    print_d(CTL_ORIANGE, "===============================================================================" CTL_RESET);
    print_info("DRAM 0x0 ~ 0x100");
    for (int i = 0; i < 16; ++i) {
        std::printf("%08x: ", i * 16);
        for (int j = 0; j < 4; ++j) {
            auto t = cpu->rootp->top__DOT__U_dram__DOT__mem[0 + i * 4 + j];
            // std::printf("%08x ", t);
            std::printf("%02x %02x %02x %02x ", t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF, (t >> 24) & 0xFF);
        }
        std::printf("\n");
    }

    print_d(CTL_ORIANGE, "===============================================================================" CTL_RESET);
    print_info("DRAM 0x100 ~ 0x10c ");
    for (int j = 0; j < 0xc / 4; ++j) {
        auto t = cpu->rootp->top__DOT__U_dram__DOT__mem[0x0100 / 4 + j];
        std::printf("%02x %02x %02x %02x ", t & 0xFF, (t >> 8) & 0xFF, (t >> 16) & 0xFF, (t >> 24) & 0xFF);
    }
    std::printf("\n");
    return;
}

template <typename T>
void serial_print_u8(T &cpu, difftest::CpuRefImpl &cpuRef, uint8_t data) {
    cpu += 20; // delay
    cpuRef.uart.putc(data);
    uart_putc(cpu, cpuRef, data);
}

template <typename T, typename Td>
void serial_print(T &cpu, difftest::CpuRefImpl &cpuRef, const Td &data) {
    constexpr size_t size = sizeof(Td);
    for (size_t i = 0; i < size; ++i) {
        serial_print_u8(cpu, cpuRef, (data >> (i * 8)) & 0xFF);
    }
}

// clang-format off
inline auto USER_PROGRAM = std::vector<uint32_t>{ // in Little-Endian
    // ###### User Program Assembly ######
    // __start:
    0x0C048002, // addi.w      $t0,$zero,0x1   # t0 = 1
    0x0D048002, // addi.w      $t1,$zero,0x1   # t1 = 1
    0x04800015, // lu12i.w     $a0,-0x7fc00    # a0 = 0x80400000
    0x85808002, // addi.w      $a1,$a0,0x20    # a1 = 0x80400020

    // loop:
    0x8E351000, // add.w       $t2,$t0,$t1     # t2 = t0+t1
    0xAC018002, // addi.w      $t0,$t1,0x0     # t0 = t1
    0xCD018002, // addi.w      $t1,$t2,0x0     # t1 = t2
    0x8E008029, // st.w        $t2,$a0,0x0
    0x84108002, // addi.w      $a0,$a0,0x4     # a0 += 4
    0x85ECFF5F, // bne         $a0,$a1,loop
    0x2000004C, // jirl        $zero,$ra,0x0
};
inline auto REG_VERIFICATION = std::vector<std::pair<uint32_t, uint32_t>>{
    {4, 0x80400020}, {5, 0x80400020},
    {12, 0x22}, {13, 0x37}, {14, 0x37}
};

inline auto MEM_VERIFICATION = std::vector<uint32_t> {
    0x02000000,
    0x03000000,
    0x05000000,
    0x08000000,
    0x0d000000,
    0x15000000,
    0x22000000,
    0x37000000,
};
// clang-format on
inline uint32_t bit_reverse(uint32_t x) {
    return ((x & 0xFF) << 24) | (((x >> 8) & 0xFF) << 16) | (((x >> 16) & 0xFF) << 8) | (((x >> 24) & 0xFF));
}


template <typename T>
void sendA(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_LIGHTBLUE, "[RunA] " CTL_RESET "Send A");
    uint32_t addr = 0x80100000;
    for (uint32_t i = 0; i < USER_PROGRAM.size(); ++i) {
        serial_print(cpu, cpuRef, 'A');
        serial_print(cpu, cpuRef, static_cast<uint32_t>(addr + i * 4));
        serial_print(cpu, cpuRef, static_cast<uint32_t>(4));
        serial_print(cpu, cpuRef, static_cast<uint32_t>(bit_reverse(USER_PROGRAM[i])));
        debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());

        debug("%c\n0x%08X\n0x%08X\n0x%08X\n", 'A', addr + i * 4, 4, static_cast<uint32_t>(USER_PROGRAM[i]));
    }
    print_d(CTL_LIGHTBLUE, "[RunA] " CTL_RESET "Send A Complete");
    // debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
}
template <typename T>
void sendD(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_LIGHTBLUE, "[RunD] " CTL_RESET "Send D");
    uint32_t addr = 0x80100000;
    uint32_t size = static_cast<uint32_t>(USER_PROGRAM.size());
    serial_print(cpu, cpuRef, 'D');
    serial_print(cpu, cpuRef, static_cast<uint32_t>(addr));
    serial_print(cpu, cpuRef, static_cast<uint32_t>(4 * size));
    // debug("%c\n0x%08X\n%08X\n%08X\n", 'D', addr, 4, 4 * size);

    print_d(CTL_LIGHTBLUE, "[RunD] " CTL_RESET "Send D Complete");
    debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
}

template <typename T>
void sendG(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_LIGHTBLUE, "[RunG] " CTL_RESET "Send G");
    uint32_t addr = 0x80100000;
    serial_print(cpu, cpuRef, 'G');
    serial_print(cpu, cpuRef, addr);
    print_d(CTL_LIGHTBLUE, "[RunG] " CTL_RESET "Send G Complete");
    debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
}

template <typename T>
void sendR(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_LIGHTBLUE, "[RunR] " CTL_RESET "Send R");
    uint32_t addr = 0x80100000;
    serial_print(cpu, cpuRef, 'R');
    print_d(CTL_LIGHTBLUE, "[RunR] " CTL_RESET "Send R Complete");
    debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
}

template <typename T>
void sendD2(T &cpu, difftest::CpuRefImpl &cpuRef) {
    print_d(CTL_LIGHTBLUE, "[RunD2] " CTL_RESET "Send D2");
    uint32_t addr = 0x80100000;
    serial_print(cpu, cpuRef, 'D');
    serial_print(cpu, cpuRef, 0x80400000);
    serial_print(cpu, cpuRef, static_cast<uint32_t>(4 * MEM_VERIFICATION.size()));
    print_d(CTL_LIGHTBLUE, "[RunD2] " CTL_RESET "Send D2 Complete");
    debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
}