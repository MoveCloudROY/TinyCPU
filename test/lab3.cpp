#include <utility>
#include <vector>
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

#include "CpuRefImpl.h"
#include "CpuTracer.h"
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

    /*=========================================================================*/
    //                               初始化开始
    /*=========================================================================*/

    srand(time(0));
    // 初始化 ExtRam
    ramdom_init_ext(LOONG_DBIN_PATH);


    // freopen("trace.txt", "w", stdout);

    // 初始化 CPU
    srand(time(0));
    difftest::CpuTracer<Vtop, CpuStatus> cpu{argc, argv};

    // CPU 监控状态回调
    auto updateFunc = [&]() -> CpuStatus {
        return {
            cpu->rootp->top__DOT__mem2wb_bus_r[0],
            cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr,
            cpu->rootp->top__DOT__U_wb__DOT__rf_wdata_o,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_avai

        };
    };
    // 注册回调
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

    // 串口输入模拟线程
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

            sendChar = c;
            sendFlag = true;
        }
    }};

    bool   running = true;
    size_t StayCnt = 0;


    auto startTime = std::chrono::high_resolution_clock::now();


    /*=========================================================================*/
    //                               初始化结束
    /*=========================================================================*/


    while (running) {
        // Prac CPU 步进
        cpu.step();

        serial_scanf(cpu, cpuRef);

        //考虑有效性，当 PC 发生变更，则有效
        if (cpu.lastStatus.pc != cpu.nowStatus.pc) {

            debug("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());

            StayCnt = 0;

            // 参考实现步进
            cpuRef.step();

            // 比较状态
            if (!compare_status(cpu.recentStatus, cpuRef.recentStatus, cpu)) {
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
            sendA(cpu, cpuRef);
            sendD(cpu, cpuRef);
        }

        if (sendFlag) {
            serial_print(cpu, cpuRef, sendChar);
            sendFlag = false;
        }

        running = !cpuRef.is_finished();

        // if (StayCnt >= 10) {
        //     print_info("Pass the DiffTest!");
        //     cpu.perfTracer.print();
        //     print_ext(cpu, cpuRef);
        //     return 0;
        //     break;
        // }
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


TEST_CASE("lab3") {
    char argv[] = {"lab3"};
    REQUIRE(test_main(0, (char **)argv) == 0);
}