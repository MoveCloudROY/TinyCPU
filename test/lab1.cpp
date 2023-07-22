#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

#include "CpuRefImpl.h"
#include "CpuTracer.h"
#include "PerfTracer.h"
#include "Tools.h"
#include "ThreadRaii.h"
#include "Structs.h"

#include "Vtop.h"
#include "Vtop___024root.h"
#include "defines.h"

#include <array>
#include <bits/chrono.h>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <iomanip>
#include <ios>
#include <ratio>
#include <sstream>
#include <thread>
#include <chrono>
#include <iostream>
#include <queue>
#include <algorithm>
#include <functional>
#include <type_traits>
#include <csignal>
#include <fstream>
#include <termios.h>


struct CpuStatus {
    uint32_t pc;
    uint32_t targetAddr;
    uint32_t targetData;
    uint32_t uartTxBusy;
    uint32_t uartRxReady;
};

int test_main(int argc, char **argv) {
    srand(time(0));
    // 初始化 ExtRam
    ramdom_init_ext(LOONG_DBIN_PATH);


    // freopen("trace.txt", "w", stdout);

    // 性能计数器
    difftest::PerfTracer perfTracer;
    // 初始化 CPU
    srand(time(0));
    difftest::CpuTracer<Vtop, CpuStatus> cpu{argc, argv};

    // CpuStatus cpu.lastStatus{};
    // CpuStatus cpu.nowStatus{};
    auto updateFunc = [&]() -> CpuStatus {
        return {
            cpu->rootp->top__DOT__mem2wb_bus_r[0],
            cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr,
            cpu->rootp->top__DOT__U_wb__DOT__rf_wdata_o,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_avai

        };
    };
    cpu.register_beforeCallback(updateFunc);
    cpu.register_afterCallback(updateFunc);
    cpu.register_getGprCallback([&]() {
        std::array<uint32_t, 32> gpr;
        std::copy(
            std::begin(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            std::end(cpu->rootp->top__DOT__U_reg_file__DOT__regfile.m_storage),
            gpr.begin()
        );
        return gpr;
    });

    cpu.enable_trace("top.vcd");
    cpu.reset_all();

    bool sendFlag = false;
    char sendChar = ' ';
    // 初始化参考实现
    difftest::CpuRefImpl cpuRef{LOONG_BIN_PATH, LOONG_DBIN_PATH, 0, 0, true, false};


    ThreadRaii uart_input_thread{[&]() {
        termios tmp;
        tcgetattr(STDIN_FILENO, &tmp);
        tmp.c_lflag &= (~ICANON & ~ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &tmp);
        while (true) {
            char c = getchar();
            debug("[UART] rx: %c", c);
            if (c == 10)
                c = 13; // convert lf to cr

            // cpuRef.uart.putc(c);
            // uart_putc(cpu, cpuRef, c);
            sendChar = c;
            sendFlag = true;
        }
    }};


    bool   running = true;
    size_t StayCnt = 0;

    auto startTime = std::chrono::high_resolution_clock::now();

    while (running) {
        // Prac CPU 步进
        cpu.step();

        bool waitingUartTx = cpu.lastStatus.uartTxBusy && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);
        // print_d(CTL_LIGHTBLUE, "PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
        /*
            串口等待处理:
                1. 检测是否进入串口发送完毕等待循环，判断当前访问地址为 UART_CTL_ADDR & uart_tx_busy
                2. 等待串口发送完毕
                3. 同步 Prac CPU和 Ref CPU
        */
        if (waitingUartTx) {
            // Ref CPU 进行取串口数据指令
            cpuRef.step();
            // print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Start Deal -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
            // 等待数据读取完成，并执行完当前指令
            while (cpu.lastStatus.uartTxBusy || cpu.lastStatus.pc == cpu.nowStatus.pc) {
                cpu.step();

                waitingUartTx = cpu.lastStatus.uartTxBusy && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);

                // print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Waiting TX -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
            }

            cpu.step();
            waitingUartTx = cpu.lastStatus.uartTxBusy && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);

            while (cpu.lastStatus.pc != cpuRef.get_pc()) {
                cpu.step();
                waitingUartTx = cpu.lastStatus.uartTxBusy && (cpu.nowStatus.targetAddr == UART_CTL_ADDR);
                // print_d(CTL_LIGHTBLUE, "[UART] " CTL_RESET "Sync -- PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());
            }
        }

        perfTracer.tick(cpu.lastStatus.pc != cpu.nowStatus.pc);

        //考虑有效性，当 PC 发生变更，则有效
        if (cpu.lastStatus.pc != cpu.nowStatus.pc) {

            debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());

            StayCnt = 0;

            // 参考实现步进
            cpuRef.step();

            // 比较状态
            if (!compare_status(cpu.recentStatus, cpuRef.recentStatus, cpu)) {
                // for (int k = 0; k < 10; ++k)
                //     cpu.step();
                // 错误时，打印出历史记录
                std::cout << "\n\n" CTL_ORIANGE "Prac CPU History:" CTL_RESET "\n";
                while (!cpu.history.empty()) {
                    debug("===============================");
                    auto s = cpu.history.front();
                    cpu.history.pop();
                    print_d(CTL_PUP, "[Prac CPU]");
                    print_d(CTL_PUP, "PC: 0x%08X", s.pc);
                    print_gpr(s.gpr);
                    print_d(CTL_RESET, "--------------------------------------");
                    auto s_ref = cpuRef.history.front();
                    cpuRef.history.pop();
                    print_d(CTL_PUP, "[Ref CPU]");
                    print_d(CTL_PUP, "PC: 0x%08X", s_ref.pc);
                    print_gpr(s_ref.gpr);
                }
                print_ext(cpu, cpuRef);
                return 1;
                break;
            }
        } else {
            ++StayCnt;
        }

        std::string RefUartTxStr{};
        std::string PracUartTxStr{};
        while (cpuRef.uart.exist_tx()) {
            char c = cpuRef.uart.getc();
            if (c != '\r') {
                RefUartTxStr += c;
                print_d(CTL_LIGHTBLUE, "[REF.UART.TX] " CTL_RESET "Receiving CPU Send: %c", c);
                fflush(stdout);
            }
        }

        while (cpu.exist_tx()) {
            char c = cpu.get_tx_c();
            if (c != '\r') {
                PracUartTxStr += c;
                print_d(CTL_LIGHTBLUE, "[Prac.UART.TX] " CTL_RESET "Receiving CPU Send: %c", c);
                fflush(stdout);
            }
        }

        if (PracUartTxStr == ".") {
            cpuRef.uart.putc('T');
            uart_putc(cpu, cpuRef, 'T');
        }

        if (sendFlag) {
            cpuRef.uart.putc(sendChar);
            uart_putc(cpu, cpuRef, sendChar);
            sendFlag = false;
        }

        running = !cpuRef.is_finished();

        if (StayCnt >= 100000) {
            print_info("Pass the DiffTest!");
            perfTracer.print();
            print_ext(cpu, cpuRef);
            return 0;
            break;
        }
        auto endTime = std::chrono::high_resolution_clock::now();
        auto during  = std::chrono::duration_cast<std::chrono::seconds>(endTime - startTime).count();

        if (during > 100) {
            print_err("CPU emulation timeout!");
            print_ext(cpu, cpuRef);
            return 1;
        }
    }
    print_ext(cpu, cpuRef);
    return 0;
}


TEST_CASE("lab2") {
    char argv[] = {"lab2"};
    REQUIRE(test_main(0, (char **)argv) == 0);
}