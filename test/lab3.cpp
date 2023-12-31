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
#include <signal.h>

constexpr size_t TRACE_DEEP = 10;


namespace {
std::function<void(int)> shutdown_handler;

void signal_handler(int signal) {
    shutdown_handler(signal);
}
} // namespace


int test_main(int argc, char **argv) {

    /*=========================================================================*/
    //                               初始化开始
    /*=========================================================================*/

    srand(time(0));
    // 初始化 ExtRam
    // ramdom_init_ext(LOONG_DBIN_PATH);


    // freopen("trace.txt", "w", stdout);

    // 初始化 CPU
    srand(time(0));
    difftest::CpuTracer<Vtop, CpuStatus> cpu{argc, argv, TRACE_DEEP};

    // CPU 监控状态回调
    auto updateFunc = [&]() -> CpuStatus {
        return {
            cpu->rootp->top__DOT__mem2wb_bus_r[0],
            cpu->rootp->top__DOT__U_wb__DOT__dbg_dm_addr,
            cpu->rootp->top__DOT__U_wb__DOT__rf_wdata_o,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_tx_busy,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_avai,
            cpu->rootp->top__DOT____Vtogcov__ext_uart_rx_ready};
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
    difftest::CpuRefImpl cpuRef{
        LOONG_BIN_PATH,
        LOONG_DBIN_PATH,
        0,
        0,
        true,
        false,
        TRACE_DEEP

    };

    shutdown_handler = [&](int signal) {
        cpuRef.stop_record();
        cpu.stop_record();
        auto f = fopen("history.txt", "w");
        forward_compare(cpu, cpuRef, 0, f);
        fclose(f);

        exit(0);
    };
    signal(SIGINT, signal_handler);

    // 串口输入模拟线程
    ThreadRaii uart_input_thread{[&]() {
        termios tmp;
        tcgetattr(STDIN_FILENO, &tmp);
        tmp.c_lflag &= (~ICANON & ~ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &tmp);
        while (true) {
            char c = getchar();
            print_dbg("[UART] rx: %c", c);
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

            print_dbg("[Main] PracPc: 0x%08X   RefPc: 0x%08X", cpu.lastStatus.pc, cpuRef.get_pc());

            StayCnt = 0;

            // 参考实现步进
            cpuRef.step();

            // 比较状态
            if (!compare_status(cpu.recentStatus, cpuRef.recentStatus, cpu)) {

                // cpuRef.stop_record();
                // cpu.stop_record();
                // auto f = fopen("history.txt", "w");
                // forward_compare(cpu, cpuRef, 0, f);
                // fclose(f);
                // exit(0);

                print_history(cpu, cpuRef);
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

            cpuRef.start_record();
            cpu.start_record();

            sendA(cpu, cpuRef);

            if (cpuRef.isRecording) {
                cpuRef.stop_record();
                cpu.stop_record();
                auto f = fopen("history.txt", "w");
                forward_compare(cpu, cpuRef, 0, f);
                fclose(f);
                exit(0);
            }
            sendD(cpu, cpuRef);

            print_d(CTL_LIGHTBLUE, "[Run.AD] " CTL_RESET "PracPc: 0x%08X   RefPc: 0x%08X", cpu.nowStatus.pc, cpuRef.get_pc());
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